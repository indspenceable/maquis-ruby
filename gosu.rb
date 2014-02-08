#!/usr/bin/env ruby
require 'gosu'
require 'yaml'

require './app/skill'
require './app/actions/base'
require './app/actions/menu_action'
require './app/actions/menu_actions/turn_menu'
require './app/actions/map_action'
require './app/actions/map_actions/unit_select'
require './app/actions/map_actions/move'
require './app/actions/attack_executor'
require './app/actions/menu_actions/attack_target_select'
require './app/actions/menu_actions/attack_weapon_select'
require './app/actions/menu_actions/confirm_move'
require './app/actions/menu_actions/inventory'
require './app/actions/unit_info'
require './app/actions/planning'
require './app/actions/enemy_turn'
require './app/actions/highlight_enemy_moves'
require './app/actions/trade'
require './app/level_generator'
require './app/level'
require './app/names'
require './app/items/weapon'
require './app/items/vulnerary'
require './app/units/base'
require './app/player_army'

#constants go here too, cause yolo

MAP_SIZE_X = 40
MAP_SIZE_Y = 30

PLAYER_TEAM = 0
COMPUTER_TEAM = 1


KEYS = {
  :left => Gosu::KbLeft,
  :right => Gosu::KbRight,
  :down => Gosu::KbDown,
  :up => Gosu::KbUp,
  :cancel => Gosu::KbX,
  :accept => Gosu::KbZ,
  :info => Gosu::KbI,
}

SAVE_FILE_PATH = File.expand_path(File.join('~', '.tarog'))
previous_save = if File.exists?(SAVE_FILE_PATH)
  YAML.load(File.read(SAVE_FILE_PATH))
end

class TileSet
  def initialize(window, filename, tile_width, tile_height, tiles_per_row)
    @store = {}
    @images = Gosu::Image.load_tiles(window, filename, tile_width, tile_height, false)
    @tiles_per_row = tiles_per_row
  end
  def define!(name, xy, frames=1, frames_per_second=1)
    x,y = xy
    @store[name] = [@tiles_per_row*y+x, frames, frames_per_second]
  end
  def keys
    @store.keys
  end
  def fetch(name, animation_frame)
    #todo frames per second
    image_index, frames, frames_per_second = @store.fetch(name)
    @images[image_index + (animation_frame/10)%frames]
  end
end

def tile_set(images, w, names)
  store = {}
  names.each do |name, (x,y)|
    store[name] = images[w*y+x]
  end
  store
end

class GosuDisplay < Gosu::Window
  Z_RANGE = {
    :terrain => 0,
    :fog => 1,
    :path => 10,
    :char => 5,
    :current_char => 20,
    :highlight => 7,
    :effects => 30,

    :menu_background => 100,
    :menu_text => 101,
    :menu_select => 102,

    :animation_overlay => 200,
  }


  TILE_SIZE_X = 16
  TILE_SIZE_Y = 16

  FONT_SIZE = 16
  FONT_BUFFER = 2

  attr_reader :current_action

  def initialize(previous_save)
    super(640, 480, false)
    action = nil
    @current_action = action || Planning.new(-1, PlayerArmy.new(6))

    @font = Gosu::Font.new(self, "futura", FONT_SIZE)

    @tiles = tile_set(
      Gosu::Image.load_tiles(self, './tiles.png', 32, 32, true),
      10,
      {
        :plains => [0,0],
        :forest => [1,0],
        :mountain => [2,0],
        :wall => [3,0],
        :fort => [3,0],
      }
    )
    @effects = TileSet.new(self, './effects.png', 32, 32, 10)
    @effects.define!(:cursor, [0,0], 4, 1)
    @effects.define!(:red_selector, [0,1], 1, 1)

    @units = TileSet.new(self, './units.png', 32, 32, 10)
    @units.define!(Fighter,       [0, 0], 2, 1)
    @units.define!(Cavalier,      [0, 1], 2, 1)
    @units.define!(ArmorKnight,   [0, 2], 2, 1)
    @units.define!(Mage,          [0, 3], 2, 1)
    @units.define!(Archer,        [0, 4], 2, 1)
    @units.define!(PegasusKnight, [0, 5], 2, 1)
    @units.define!(Myrmidon,      [0, 6], 2, 1)
    @units.define!(Nomad,         [2, 0], 2, 1)
    @units.define!(WyvernRider,   [2, 1], 2, 1)
    @units.define!(Thief,         [2, 2], 2, 1)
    @units.define!(Monk,          [2, 3], 2, 1)
    @units.define!(Mercenary,     [2, 4], 2, 1)
    @units.define!(Shaman,        [2, 5], 2, 1)
    @units.define!(Soldier,       [2, 6], 2, 1)
    @units.define!(Brigand,       [4, 0], 2, 1)

    @battle_animations = TileSet.new(self, './battle.png', 320, 240, 1)
    @battle_animations.define!(:battle, [0,0], 1, 1)
  end

  def update
    old_action = @current_action
    @current_action= @current_action.auto if @current_action.respond_to?(:auto)
    if old_action != @current_action && @current_action.respond_to?(:precalculate!)
      @current_action.precalculate!
    end
  end

  def button_down(id)
    old_action = @current_action
    if id == KEYS[:cancel]
      @current_action = @current_action.cancel
    else
      @current_action = @current_action.key(id)
    end
    if old_action != @current_action && @current_action.respond_to?(:precalculate!)
      @current_action.precalculate!
    end
  end

  def draw
    @frame ||= 0
    @frame += 1
    @current_action.draw(self)
  end

  def draw_char_at(x, y, unit, current)
    c = if unit.team == PLAYER_TEAM
      Gosu::Color::BLUE
    else
      Gosu::Color::RED
    end

    layer = current ? :current_char : :char

    @units.fetch(unit.class, @frame * (current ? 2 : 1)).draw_as_quad(
      (x+0)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, c,
      (x+1)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, c,
      (x+1)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, c,
      (x+0)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, c,
      Z_RANGE[layer])
  end

  def draw_terrain(x,y, terrain, seen)
    # TODO this lives somewhere else.
    @tiles.fetch(terrain).draw_as_quad(
      (x+0)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, Gosu::Color::WHITE,
      (x+1)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, Gosu::Color::WHITE,
      (x+1)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, Gosu::Color::WHITE,
      (x+0)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, Gosu::Color::WHITE,
      Z_RANGE[:terrain])

    draw_quad(
      (x+0)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, 0x55000000,
      (x+1)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, 0x55000000,
      (x+1)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, 0x55000000,
      (x+0)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, 0x55000000,
      Z_RANGE[:fog]) unless seen
  end

  def highlight(hash_of_space_to_color)
    hash_of_space_to_color.each do |(x,y), color|
      if @effects.keys.include?(color)
        @effects.fetch(color, @frame).draw_as_quad(
          (x+0)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, Gosu::Color::WHITE,
          (x+1)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, Gosu::Color::WHITE,
          (x+1)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, Gosu::Color::WHITE,
          (x+0)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, Gosu::Color::WHITE,
          Z_RANGE[:effects])
      else
        c = case color
        when :red
          0x99ff0000
        when :blue
          0x990000ff
        end
        draw_quad(
          (x+0)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, c,
          (x+1)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, c,
          (x+1)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, c,
          (x+0)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, c, Z_RANGE[:highlight])
      end
    end
  end

  def draw_path(path)
    path.each do |x,y|
      quad(x*TILE_SIZE_X+10, y*TILE_SIZE_Y+10, TILE_SIZE_X-20, TILE_SIZE_Y-20, 0xff00ff88, Z_RANGE[:path])
    end
  end

  def draw_cursor(x,y)
    c = Gosu::Color::CYAN
    @effects.fetch(:cursor, @frame).draw_as_quad(
      (x+0)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, c,
      (x+1)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, c,
      (x+1)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, c,
      (x+0)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, c, Z_RANGE[:effects])
  end

  def draw_menu(options, index)
    xo,yo = 10, 10
    quad(xo, yo, 200, options.count*(FONT_SIZE+FONT_BUFFER), Gosu::Color::WHITE, Z_RANGE[:menu_background])
    options.each_with_index do |o,i|
      @font.draw(o, xo+5, yo + i*(FONT_SIZE+FONT_BUFFER) + 1, Z_RANGE[:menu_text], 1, 1, Gosu::Color::BLACK)
    end
    quad(xo, yo + index*(FONT_SIZE+FONT_BUFFER)+1, 5, FONT_SIZE, Gosu::Color::RED, Z_RANGE[:menu_select])
  end

  def draw_character_info(u1, u2, ignore_range)
  end

  def show_trade(u1, u2, highlighted_item)
  end

  def extended_character_info(unit)
    [
      unit.name,
      "#{unit.klass}: #{unit.exp_level}",
      "% 3d/100 xp" % unit.exp,
      "#{unit.health_str} hp",
      unit.power_for_info_str,
      unit.skill_for_info_str,
      unit.armor_for_info_str,
      unit.speed_for_info_str,
      unit.resistance_for_info_str,
      unit.weapon_name_str,
      "#{unit.constitution}",
      unit.traits.map(&:to_s).join(', '),
      unit.instance_variable_get(:@skills).map(&:identifier).map(&:to_s).join(','),
    ].each_with_index do |string, i|
      @font.draw string, 10, i*16, 1
    end
  end

  def character_list_for_planning(menu_items, current_item)
    # OH MAN this is bad looking. Fixit!
    menu_items.each_with_index do |m,i|
      @font.draw(m.inspect, 10, i*(FONT_SIZE+FONT_BUFFER), 1)
      if m == current_item
        quad(0, i*(FONT_SIZE+FONT_BUFFER), 16, 16, Gosu::Color::WHITE, 1)
      end
    end
  end

  def draw_battle_animation(unit1, unit2)
    if @drawing_battle_animation == [unit1, unit2]
      @animation_frame += 1
    else
      @animation_frame = 0
    end
    @drawing_battle_animation = [unit1, unit2]

    @battle_animations.fetch(:battle, @animation_frame).draw_as_quad(
        160+0,   120+0, Gosu::Color::WHITE,
      160+320,   120+0, Gosu::Color::WHITE,
      160+320, 120+240, Gosu::Color::WHITE,
        160+0, 120+240, Gosu::Color::WHITE,
      Z_RANGE[:animation_overlay])

    if @animation_frame >= 30
      @drawing_battle_animation = nil
      return true
    end
  end

  private

  def quad(x,y,w,h,c,z)
    draw_quad(
      x+w,   y, c,
      x+w, y+h, c,
        x, y+h, c,
        x,   y, c,
      z)
  end
end

DISPLAY = GosuDisplay.new(previous_save)
Gosu::enable_undocumented_retrofication


def save_game
  File.open(SAVE_FILE_PATH, 'w+', 0644) do |f|
    f << YAML.dump(DISPLAY.current_action)
  end
end

DISPLAY.show

