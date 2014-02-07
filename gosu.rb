#!/usr/bin/env ruby
require 'gosu'
require 'yaml'

KEYS = {
  :left => Gosu::KbLeft,
  :right => Gosu::KbRight,
  :down => Gosu::KbDown,
  :up => Gosu::KbUp,
  :cancel => Gosu::KbX,
  :accept => Gosu::KbZ,
  :info => Gosu::KbI,
}


require './app/game_runner'
SAVE_FILE_PATH = File.expand_path(File.join('~', '.tarog'))
previous_save = if File.exists?(SAVE_FILE_PATH)
  YAML.load(File.read(SAVE_FILE_PATH))
end

class GosuDisplay < Gosu::Window
  include GameRunner

  def initialize(previous_save)
    super(640, 480, false)
    setup(nil)
    @font = Gosu::Font.new(self, "courier", 12)
  end

  def update
  end

  def button_down(id)
    old_action = @current_action
    if id == KEYS[:cancel]
      @current_action = @current_action.cancel
    else
      puts (KEYS.invert)[id]
      @current_action = @current_action.key(id)
    end

    if old_action != @current_action && @current_action.respond_to?(:precalculate!)
      @current_action.precalculate!
    end
  end

  def draw
    @main_screen_draw = false
    @current_action.draw(self)
  end

  def main_screen_draw
    raise "Already drew the main screen!" if @main_screen_draw
    @main_screen_draw = true
  end

  TILE_SIZE_X = 32
  TILE_SIZE_Y = 32

  def draw_char_at(x, y, unit)
    c = if unit.team == PLAYER_TEAM
      Gosu::Color::BLUE
    else
      Gosu::Color::RED
    end
    draw_quad(
      (x+0)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, c,
      (x+1)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, c,
      (x+1)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, c,
      (x+0)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, c, 1)
  end

  def draw_terrain(x,y, tile, seen)
    c = case tile
    when :plains
      Gosu::Color::YELLOW
    when :forest
      Gosu::Color::GREEN
    when :mountain
      Gosu::Color::FUCHSIA
    else
      Gosu::Color::GRAY
    end

    draw_quad(
      (x+0)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, c,
      (x+1)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, c,
      (x+1)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, c,
      (x+0)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, c, 0)

    draw_quad(
      (x+0)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, 0x55000000,
      (x+1)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, 0x55000000,
      (x+1)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, 0x55000000,
      (x+0)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, 0x55000000, 0) unless seen
  end

  def highlight(hash_of_space_to_color)
    hash_of_space_to_color.each do |(x,y), color|
      c = case color
      when :red
        0x55ff0000
      when :blue
        0x550000ff
      end
      draw_quad(
        (x+0)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, c,
        (x+1)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, c,
        (x+1)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, c,
        (x+0)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, c, 0)
    end
  end

  def draw_path(path)
    path.each do |x,y|
      quad(x*TILE_SIZE_X+5, y*TILE_SIZE_Y+5, TILE_SIZE_X-10, TILE_SIZE_Y-10, Gosu::Color::BLACK, 2)
    end
  end

  def draw_cursor(x,y)
    c = Gosu::Color::CYAN
    draw_quad(
      (x+0)*TILE_SIZE_X+1, (y+0)*TILE_SIZE_Y+1, c,
      (x+1)*TILE_SIZE_X-1, (y+0)*TILE_SIZE_Y+1, c,
      (x+1)*TILE_SIZE_X-1, (y+1)*TILE_SIZE_Y-1, c,
      (x+0)*TILE_SIZE_X+1, (y+1)*TILE_SIZE_Y-1, c, 3)
  end

  def draw_menu(options, index)
    quad(10, 10, 50, options.count*14, Gosu::Color::WHITE, 10)
    options.each_with_index do |o,i|
      @font.draw(o, 15, 10+ i*14 + 1, 20, 1, 1, Gosu::Color::BLACK)
    end
    quad(10, 10 + index*14+1, 5, 12, Gosu::Color::RED, 21)
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
      @font.draw(m.inspect, 10, i*16, 1)
      if m == current_item
        quad(0, i*16, 16, 16, Gosu::Color::WHITE, 1)
      end
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

def save_game
  File.open(SAVE_FILE_PATH, 'w+', 0644) do |f|
    f << YAML.dump(DISPLAY.current_action)
  end
end

DISPLAY.show

