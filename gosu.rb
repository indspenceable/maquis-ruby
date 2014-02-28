#!/usr/bin/env ruby
require 'gosu'
require 'yaml'
require 'set'

#constants go here too, cause yolo

MAP_SIZE_X = 20
MAP_SIZE_Y = 15

Dir[File.join(File.dirname(__FILE__), "app/**/*.rb")].sort.each do |f|
  require f
end

MILD_BLUE = Gosu::Color.new(255, 175, 175, 255)
USED_BLUE = Gosu::Color.new(255, 100, 100, 100)
MILD_RED  = Gosu::Color.new(255, 255, 175, 175)

PLAYER_TEAM = 0
COMPUTER_TEAM = 1

def round(x)
  (x + 0.5).to_i
end

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

class TileSetProxy
  def initialize(tilesets)
    @store = {}
    tilesets.each do |ts|
      ts.keys.each do |k|
        if @store.key?(k)
          raise "duplicate key!"
        else
          @store[k] = ts
        end
      end
    end
  end
  def fetch(name, *args)
    @store[name].fetch(name, *args)
  end
  def finished?(name, *args)
    @store[name].finished?(name, *args)
  end
end

class SingleImageTileSet
  def initialize(window, filename, tile_width, tile_height, tiles_per_row)
    @store = {}
    @images = Gosu::Image.load_tiles(window, filename, tile_width, tile_height, true)
    @tiles_per_row = tiles_per_row
  end
  def define!(name, xy, frames=1, ticks_per_frame=1, repeat=true)
    x,y = xy
    @store[name] = [@tiles_per_row*y+x, frames, ticks_per_frame, repeat]
  end
  def keys
    @store.keys
  end
  def fetch(name, animation_frame)
    image_index, frames, ticks_per_frame, repeat = @store.fetch(name)
    frame_number = if repeat
      (animation_frame/ticks_per_frame)%frames
    else
      [(animation_frame/ticks_per_frame), frames-1].min
    end
    @images[image_index + frame_number]
  end
  def finished?(name, animation_frame)
    _, frames, ticks_per_frame = @store.fetch(name)
    animation_frame >= (frames*ticks_per_frame)-1
  end
end

class MultiImageTileSet < SingleImageTileSet
  def initialize(window, filenames, tile_width, tile_height, tiles_per_row)
    @store = {}
    images = filenames.map do |f|
      Gosu::Image.load_tiles(window, f, tile_width, tile_height, true)
    end
    @images = []
    images.first.length.times do |i|
      images.each do |im|
        @images << im[i]
      end
    end
    @frame_count = filenames.length
    @tiles_per_row = tiles_per_row*filenames.length
  end
  def define!(name, xy, ticks_per_frame=1, repeat=true)
    x,y = xy
    xy = [@frame_count*x, y]
    super(name, xy, @frame_count, ticks_per_frame, repeat)
  end
  def mass_define(ticks_per_frame, repeat, name_to_xy)
    name_to_xy.each do |name, xy|
      define!(name, xy, ticks_per_frame, repeat)
    end
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


  TILE_SIZE_X = 32
  TILE_SIZE_Y = 32
  FONT_SIZE = 18
  FONT_BUFFER = 2

  WINDOW_SIZE_X = 640
  WINDOW_SIZE_Y = 480
  WINDOW_TILES_X = WINDOW_SIZE_X / TILE_SIZE_X
  WINDOW_TILES_Y =  WINDOW_SIZE_Y / TILE_SIZE_Y


  attr_reader :current_action

  def initialize(previous_save)
    super(WINDOW_SIZE_X, WINDOW_SIZE_Y, false)
    action = previous_save
    @current_action = action || Planning.new(-1, PlayerArmy.new)

    @font = Gosu::Font.new(self, "DawnLike/GUI/SDS_6x6.ttf", FONT_SIZE)
    define_tile_sets
    @camera_x = 0
    @camera_y = 0

    @camera_target_x = 0
    @camera_target_y = 0

    @keys = {}

    @buttons_down = Set.new
    @button_timer = 0
  end

  def define_tile_sets
    @menu = MultiImageTileSet.new(self, [
      './DawnLike/GUI/GUI0.png',
      './DawnLike/GUI/GUI1.png',
      ],
      16, 16, 16)
    @menu.define!(:tl, [1,6])
    @menu.define!(:t,  [2,6])
    @menu.define!(:tr, [3,6])
    @menu.define!(:l,  [1,7])
    @menu.define!(:m,  [2,7])
    @menu.define!(:r,  [3,7])
    @menu.define!(:bl, [1,8])
    @menu.define!(:b,  [2,8])
    @menu.define!(:br, [3,8])

    land_tiles = SingleImageTileSet.new(self, './DawnLike/Objects/Floors.png', 16, 16, 21)
    land_tiles.define!(:plains, [8, 7], 1, 1)
    land_tiles.define!(:mountain, [15, 7])
    land_tiles.define!(:wall, [15, 10])

    tree_tiles = MultiImageTileSet.new(self, [
        './DawnLike/Objects/Trees0.png',
        './DawnLike/Objects/Trees1.png',
      ], 16, 16, 8)
    tree_tiles.define!(:forest, [3,0])
    tree_tiles.define!(:fort, [1,1])

    decor_tiles = MultiImageTileSet.new(self, [
        './DawnLike/Objects/Decor0.png',
        './DawnLike/Objects/Decor1.png',
      ], 16, 16, 8)
    decor_tiles.define!(:shop, [7, 5])
    decor_tiles.define!(:closed_shop, [7, 4])


    @tiles = TileSetProxy.new([land_tiles, tree_tiles, decor_tiles])

    @path = SingleImageTileSet.new(self, './path.png', 33, 32, 15)
    @path.define!(:right_right, [0,0], 1, 1)
    @path.define!(:left_left,   [0,0], 1, 1)
    @path.define!(:up_up,       [1,0], 1, 1)
    @path.define!(:down_down,   [1,0], 1, 1)
    @path.define!(:start_end,   [2,0], 1, 1)

    @path.define!(:left_end,  [0,1], 1, 1)
    @path.define!(:down_end,  [1,1], 1, 1)
    @path.define!(:right_end, [2,1], 1, 1)
    @path.define!(:up_end,    [3,1], 1, 1)

    @path.define!(:start_right, [0,1], 1, 1)
    @path.define!(:start_up,    [1,1], 1, 1)
    @path.define!(:start_left,  [2,1], 1, 1)
    @path.define!(:start_down,  [3,1], 1, 1)

    @path.define!(:up_right,  [0,2], 1, 1)
    @path.define!(:left_down, [0,2], 1, 1)

    @path.define!(:up_left,    [1,2], 1, 1)
    @path.define!(:right_down, [1,2], 1, 1)

    @path.define!(:down_right, [2,2], 1, 1)
    @path.define!(:left_up,    [2,2], 1, 1)

    @path.define!(:down_left, [3,2], 1, 1)
    @path.define!(:right_up,  [3,2], 1, 1)

    @effects = SingleImageTileSet.new(self, './effects.png', 32, 32, 10)
    @effects.define!(:cursor, [0,0], 4, 5)
    @effects.define!(:red_selector, [0,1], 1, 30)

    basic_hash = {}
    Enemy.config.merge(PlayerUnit.config).each do |k, v|
      tileset = v['tileset']
      tile = v['tile']
      basic_hash[k] = [tileset, tile] if tile
    end
    better_hash = {}
    basic_hash.each do |k,(ts, t)|
      %w(idle attack hit death).each do |w|
        better_hash[ts] ||= {}
        better_hash[ts][:"#{k}_#{w}"] = t
      end
    end
    tile_sets = []
    better_hash.each do |ts_name, ts_hash|
      actual_tile_set = MultiImageTileSet.new(self, [
        "./DawnLike/Characters/#{ts_name}0.png",
        "./DawnLike/Characters/#{ts_name}1.png",
      ], 16, 16, 8)
      actual_tile_set.mass_define(30, true, ts_hash)
      tile_sets << actual_tile_set
    end

    @all_units = TileSetProxy.new(tile_sets)
  end

  def change_current_action!(action)
    return if action == @current_action
    raise "#{@current_action} transitioned to nil!" if action.nil?
    action.precalculate! if action.respond_to?(:precalculate)
    save_game(action)
    @current_action = action
  end

  def trigger_sticky_keys!
    if @button_timer > 7
      @buttons_down.each do |b|
        button_down(b)
      end
      @button_timer -= 2
    else
      @button_timer += 1
    end
  end

  def track_key_press!(id)
    @button_timer = 0 unless @buttons_down.include?(id)
    @buttons_down << id if [
      KEYS[:left],
      KEYS[:right],
      KEYS[:up],
      KEYS[:down],
    ].include?(id)
  end

  def update
    trigger_sticky_keys!
    if @current_action.respond_to?(:auto)
      change_current_action!(@current_action.auto)
    end
  end

  def button_down(id)
    track_key_press!(id)
    if id == KEYS[:cancel]
      change_current_action!(@current_action.cancel)
    else
      change_current_action!(@current_action.key(id))
    end
  end

  def button_up(id)
    @buttons_down.delete(id)
  end

  def draw
    @frame ||= 0
    @frame += 1

    @ccx, @ccy = round(@camera_x), round(@camera_y)
    translate(-@ccx, -@ccy) do
      @current_action.draw(self)
    end
  end

  def self.no_camera(meth)
    original_method_name = "original_#{meth}"
    alias_method original_method_name, meth
    define_method(meth) do |*args|
      translate(@ccx, @ccy) do
        self.__send__(original_method_name, *args)
      end
    end
  end

  def draw_char_at(x, y, unit, current, animation, frame=@frame)
    c = if unit.team == PLAYER_TEAM
      if unit.action_available
        MILD_BLUE
      else
        USED_BLUE
      end
    else
      MILD_RED
    end

    layer = current ? :current_char : :char

    @all_units.fetch(unit.animation_for(animation), frame).draw_as_quad(
      (x+0)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, Gosu::Color::WHITE,
      (x+1)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, Gosu::Color::WHITE,
      (x+1)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, Gosu::Color::WHITE,
      (x+0)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, Gosu::Color::WHITE,
      Z_RANGE[layer])

    border_size = 2

    quad(TILE_SIZE_X*x, TILE_SIZE_Y*y, TILE_SIZE_X, border_size, c, Z_RANGE[layer])
    quad(TILE_SIZE_X*x, TILE_SIZE_Y*(y+1)-border_size, TILE_SIZE_X, border_size, c, Z_RANGE[layer])
    quad(TILE_SIZE_X*(x+1)-border_size, TILE_SIZE_Y*y, border_size, TILE_SIZE_Y, c, Z_RANGE[layer])
    quad(TILE_SIZE_X*x, TILE_SIZE_Y*y, border_size, TILE_SIZE_Y, c, Z_RANGE[layer])

    return @all_units.finished?(unit.animation_for(animation), frame)
  end
  # camera_function :draw_char_at

  def draw_map(level)
    (screen_left_tile.to_i-1..screen_right_tile.to_i+1).each do |x|
      (screen_top_tile.to_i-1..screen_bottom_tile.to_i+1).each do |y|
        terrain = level.map(x,y).tile
        seen = level.see?(x,y)
        # TODO this lives somewhere else.
        @tiles.fetch(terrain, @frame).draw_as_quad(
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
    end
  end
  # no_camera :draw_terrain

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
    path.each_with_direction do |(x,y), direction|
      @path.fetch(direction, @frame).draw_as_quad(
        (x+0)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, Gosu::Color::WHITE,
        (x+1)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, Gosu::Color::WHITE,
        (x+1)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, Gosu::Color::WHITE,
        (x+0)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, Gosu::Color::WHITE,
        Z_RANGE[:path])
    end
  end

  def screen_left_tile
    @camera_x/TILE_SIZE_X
  end
  def screen_right_tile
    (@camera_x + WINDOW_SIZE_X)/TILE_SIZE_X
  end
  def screen_top_tile
    @camera_y/TILE_SIZE_Y
  end
  def screen_bottom_tile
    (@camera_y + WINDOW_SIZE_Y)/TILE_SIZE_Y
  end

  def move_camera(x, y, tiles_x, tiles_y)

    if x > screen_right_tile-3
      @camera_x += (x - screen_right_tile+3)*TILE_SIZE_X / 3.0
    elsif x < screen_left_tile+3
      @camera_x -= (screen_left_tile+3 - x)*TILE_SIZE_X / 3.0
    end
    @camera_x = [[@camera_x, 0].max, (tiles_x - WINDOW_TILES_X)*TILE_SIZE_X].min

    if y > screen_bottom_tile-3
      @camera_y += (y - screen_bottom_tile+3)*TILE_SIZE_Y / 3.0
    elsif y < screen_top_tile+3
      @camera_y -= (screen_top_tile+3 - y)*TILE_SIZE_Y / 3.0
    end
    @camera_y = [@camera_y, 0].max
    @camera_y = [@camera_y, (tiles_y - WINDOW_TILES_Y)*TILE_SIZE_Y].min
  end

  def draw_cursor(x,y)
    c = Gosu::Color::CYAN
    @effects.fetch(:cursor, @frame).draw_as_quad(
      (x+0)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, c,
      (x+1)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, c,
      (x+1)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, c,
      (x+0)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, c, Z_RANGE[:effects])
  end

  def compare_units(unit1, unit2)
    attrs = [
      :name,
      :pretty_name,
      :hp,
      :power_vs,
      :accuracy,
      :crit_chance,
      :double_attack?,
      :weapon_triangle_bonus_string
    ]

    labels = [
      "",
      "",
      "HP",
      "Pow",
      "Acc",
      "Crt",
      "2x",
      "",
    ]

    strings = attrs.map do |m|
      if unit1.method(m).arity == 0
        [unit1.__send__(m), unit2.__send__(m)]
      else
        [unit1.__send__(m, unit2), unit2.__send__(m, unit1)]
      end
    end
    jst = strings.map{|a| a.first.to_s.length}.max

    menu = []
    strings.length.times do |i|
      s1, s2 = strings[i]
      menu << "#{s1.to_s.rjust(jst)} #{labels[i].center(3)} #{s2.to_s}"
    end

    draw_menu(menu,nil)
  end

  def draw_menu(options, index)
    xo,yo = 16, 16
    border_buffer_x = 3
    border_buffer_y = 3
    w_tiles = ((options.max_by(&:length).length*FONT_SIZE).to_f/16).ceil
    h_tiles = ((options.count*FONT_SIZE + border_buffer_y+2).to_f/16).ceil
    width, height = w_tiles*16, h_tiles*16

    w_tiles.times do |x|
      h_tiles.times do |y|
        yp = if y == 0
          :t
        elsif y == h_tiles-1
          :b
        end
        xp = if x == 0
          :l
        elsif x == w_tiles-1
          :r
        end

        sym = "#{yp}#{xp}"
        sym = :m if sym == ""
        @menu.fetch(sym.to_sym,0).draw(xo+x*16,yo+y*16, Z_RANGE[:menu_text])
      end
    end

    options.each_with_index do |o,i|
      @font.draw(o, xo+border_buffer_x+5, yo + i*(FONT_SIZE) + border_buffer_y, Z_RANGE[:menu_text], 1, 1, Gosu::Color::WHITE)
    end
    if index
      quad(xo+border_buffer_x, yo + index*(FONT_SIZE)+border_buffer_y, 5, FONT_SIZE, Gosu::Color::RED, Z_RANGE[:menu_select])
    end
  end
  no_camera :draw_menu

  def draw_character_info(u1, u2, ignore_range)
  end

  def show_trade(u1, u2, highlighted_item)
  end

  def extended_character_info(unit)
    quad(@camera_x,@camera_y,WINDOW_SIZE_X,WINDOW_SIZE_Y,Gosu::Color::WHITE,0)
    draw_menu([
      unit.name,
      "#{unit.pretty_name}: #{unit.exp_level}",
      unit.exp_string,
      '',
      unit.health_for_info_str,
      unit.power_for_info_str,
      unit.skill_for_info_str,
      unit.armor_for_info_str,
      unit.speed_for_info_str,
      unit.resistance_for_info_str,
      "CON: #{unit.constitution}",
      unit.weapon_name_str,
      unit.traits.map(&:to_s).join(', '),
      unit.skills.map(&:pretty).join(','),
    ],nil)
    # ].each_with_index do |string, i|
    #   @font.draw string, 10, i*16, 1
    # end
  end

  def character_list_for_planning(menu_items, current_item)
    quad(0,0,WINDOW_SIZE_X,WINDOW_SIZE_Y,Gosu::Color::WHITE,0)
    # OH MAN this is bad looking. Fixit!
    menu_items.each_with_index do |m,i|
      if m.is_a?(Unit)
        draw_char_at(1, i, m, false, :idle)
        @font.draw(m.summary, TILE_SIZE_X*2, i*(TILE_SIZE_Y), 1, 1, 1, Gosu::Color::BLACK)
      else
        @font.draw(m.to_s, TILE_SIZE_X, i*(TILE_SIZE_Y), 1, 1, 1, Gosu::Color::BLACK)
      end
      if m == current_item
        quad(0, TILE_SIZE_Y*i, TILE_SIZE_X, TILE_SIZE_Y, Gosu::Color::BLACK, 1)
      end
    end
  end

  no_camera :character_list_for_planning

  def draw_battle_animation(unit1, unit2, damage, identifier)
    if @drawing_battle_animation == identifier
      @animation_frame += 1
    else
      @animation_frame = 0
    end
    @drawing_battle_animation = identifier

    # color = (unit1.team == PLAYER_TEAM) ? Gosu::Color::BLUE : Gosu::Color::RED

    # @battle_animations.fetch(:battle, @animation_frame).draw_as_quad(
    #     160+0,   120+0, color,
    #   160+320,   120+0, color,
    #   160+320, 120+240, color,
    #     160+0, 120+240, color,
    #   Z_RANGE[:animation_overlay])
    finished = case damage
    when Fixnum,String
      [
        draw_char_at(unit1.x, unit1.y, unit1, true, :attack, @frame),
        draw_char_at(unit2.x, unit2.y, unit2, true, :hit, @frame),
        draw_rising_text(unit2.x, unit2.y, damage.to_s, 30, @animation_frame, 2),
      ]
    when :miss
      [
        draw_char_at(unit1.x, unit1.y, unit1, true, :attack, @frame),
        draw_char_at(unit2.x, unit2.y, unit2, true, :idle, @frame),
        draw_rising_text(unit1.x, unit1.y, "Miss!", 30, @animation_frame, 2),
      ]
    when :death
      [
        draw_char_at(unit1.x, unit1.y, unit1, true, :death, @frame),
        # draw_char_at(unit2.x, unit2.y, unit2, true, :idle, @animation_frame),
        draw_rising_text(unit1.x, unit1.y, "Death!", 30, @animation_frame, 0),
      ]
    end.all?
  end

  def draw_exp_meter(exp)
    quad(50, 50, 500, 50, Gosu::Color::WHITE, 300)
    quad(50, 50, (exp%100)*5, 50, Gosu::Color::RED, 301)
  end
  no_camera :draw_exp_meter

  def draw_hud(level)
    draw_menu([
      level.primary_objective.description,
      "$#{level.army.money}",
      "",
      *level.secondary_objective_descriptions
    ], nil)
  end

  private

  def draw_rising_text(tx, ty, text, frames, current_frame, speed)
    return true if current_frame >= frames
    color = Gosu::Color.rgba(255, 255, 255, 255-((128.0/frames)*current_frame).to_i)
    @font.draw_rel(text,
      (tx+0.5)*TILE_SIZE_X,
      (ty+0.5)*TILE_SIZE_Y - speed*current_frame ,
      Z_RANGE[:animation_overlay],
      0.5, 0.5,
      1, 1,
      color
    )
    false
  end

  def quad(x,y,w,h,c,z)
    draw_quad(
      x+w,   y, c,
      x+w, y+h, c,
        x, y+h, c,
        x,   y, c,
      z)
  end
end

Gosu::enable_undocumented_retrofication
DISPLAY = GosuDisplay.new(previous_save)

def save_game(action)
  dump = YAML.dump(action)
  begin
    YAML.load(dump)
    File.open(SAVE_FILE_PATH, 'w+', 0644) do |f|
      f << YAML.dump(action)
    end
  rescue
  end
end

DISPLAY.show
