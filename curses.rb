require 'curses'
require './lib/display/region'
require './lib/display/screen'
require './lib/actions/menu'
require './lib/actions/map_select'
require './lib/actions/move'
require './lib/actions/confirm_move'
require './lib/actions/enemy_turn'

class Object
  def self.attrs *attr_list
    attr_accessor *attr_list
    define_method(:initialize) do |*args|
      attr_list.each do |sym|
        send("#{sym}=", args.shift)
      end
    end
  end
end

require './lib/units/base'

MAP_SIZE_X = 40
MAP_SIZE_Y = 20

BLUE = 1
RED = 2
GREEN = 3

PLAYER_TEAM = 0
COMPUTER_TEAM = 1

TEAM_TO_COLOR = {
  0 => BLUE,
  1 => RED
}

class GS
  def self.current
    @current_state
  end
  def self.current= gs
    @current_state = gs
  end
end

class Level
  attr_reader :map, :units, :log
  def initialize(w,h)
    @w,@h = w,h
    @units = []
    @log = []
  end
  def fill
    @map = Array.new(@w) do
      Array.new(@h) do
        yield
      end
    end
  end
  def unit_at(x,y)
    units.find{|c| c.x == x && c.y == y}
  end
end

class PlayerTurn
  def initialize
    @level = Level.new(MAP_SIZE_X, MAP_SIZE_Y)
    @level.fill do
      if rand(5) == 0
        '#'
      else
        '.'
      end
    end
    20.times do |x|
      kl = case(rand(3))
      when 0
        ArmorKnight
      when 1
        Archer
      when 2
        Cavalier
      end
      u = kl.new(rand(2), "char#{x}", rand(40), rand(20))
      @level.map[u.x][u.y] = '.'
      @level.units << u
    end
    @x, @y = 1, 1
    @current_action = MapSelect.new(3, 3, @level)
  end
  def add_glyph(screen,x,y, highlight_squares)
    screen.map.set_xy(x,y)
    c = @level.unit_at(x,y)
    if c
      color = TEAM_TO_COLOR[c.team]
      attrs = c.action_available ? 0 : Curses::A_BOLD
      return screen.map.draw_str(c.glyph, color, attrs)
    end

    # c = @current_action.unit_for_map_highlighting
    # if c && Path.shortest_between(c.x,c.y, x, y, @level, c.movement)
    if highlight_squares.include?([x,y])
      screen.map.draw_str(@level.map[x][y], 0, Curses::A_REVERSE)
    else
      screen.map.draw_str(@level.map[x][y], 0)
    end
    # dim if it's out of range.
  end

  def display_character_info_for(screen, unit, i, vs=nil)
    x = i*20

    #name
    screen.info.set_xy(x, 0)
    screen.info.draw_str(unit.name.capitalize, TEAM_TO_COLOR[unit.team])
    screen.info.set_xy(x, 1)
    screen.info.draw_str(unit.klass)
    screen.info.set_xy(x, 2)
    screen.info.draw_str(unit.health_str, unit.health_color)
    if vs
      # combat stats - Power, Strength, Crit
      screen.info.set_xy(x,4)
      screen.info.draw_str(unit.power_vs(vs).to_s)
      screen.info.set_xy(x,5)
      screen.info.draw_str(unit.accuracy_vs(vs).to_s)
      screen.info.set_xy(x,6)
      screen.info.draw_str(unit.crit_chance)
      screen.info.set_xy(x, 7)
      screen.info.draw_str("x2") if unit.double_attack?(vs)
    end
  end
  def display_character_info(screen)
    screen.info.clear
    u1, u2 = @current_action.units_for_info_panel
    enemies = false
    if u1
      enemies = u2 && u1.team != u2.team
      display_character_info_for(screen, u1, 0, enemies && u2)
    end
    if u2
      display_character_info_for(screen, u2, 1, enemies && u1)
    end
    screen.info.set_xy(0, 10)
    screen.info.draw_str(@current_action.class.name)
  end

  def display_messages(screen)
    screen.messages.clear
  end

  def display_map(screen)
    #at this point, discover what paths we can go to.
    highlight_spaces = []
    c = @current_action.unit_for_map_highlighting
    if c
      highlight_spaces += Path.discover_paths(c.x, c.y, @level, c.movement).map(&:last_point)
    end
    MAP_SIZE_X.times do |x|
      MAP_SIZE_Y.times do |y|
        add_glyph(screen,x,y, highlight_spaces)
      end
    end

  end

  def display(screen)
    display_map(screen)
    display_character_info(screen)
    display_messages(screen)

    @current_action.draw(screen)
    # screen.map.set_xy(@x,@y)
    Curses::refresh
  end

  def execute
    @current_action = @current_action.execute if @current_action.respond_to?(:execute)
  end

  def move_to_correct_space(screen)
    @current_action.set_cursor(screen)
  end

  def key(c)
    if %w(h j k l a).include?(c)
      @current_action = @current_action.key(c)
    end

    if c == 27
      @current_action = @current_action.cancel
    end
  end
end

Screen.open do |s|
  GS.current = PlayerTurn.new
  loop do
    current = GS.current
    current.execute
    current.display(s)
    current.move_to_correct_space(s)
    current.key(Curses::getch)
  end
end
