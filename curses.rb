require 'curses'
require './lib/permissive_fov'
require './lib/display/region'
require './lib/display/screen'
require './lib/actions/menu'
require './lib/actions/map_select'
require './lib/actions/move'
require './lib/actions/confirm_move'
require './lib/actions/enemy_turn'
require './lib/level'

$log = []

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

require './lib/items/weapon'
require './lib/units/base'

MAP_SIZE_X = 40
MAP_SIZE_Y = 20

BLUE = 1
RED = 2
GREEN = 3

PLAYER_TEAM = 0
COMPUTER_TEAM = 1

TEAM_TO_COLOR = {
  0 => GREEN,
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

class PlayerTurn
  def initialize
    klasses = [ArmorKnight, Archer, Cavalier, Myrmidon, Mercenary].shuffle
    l = 3
    pl = 5.times.map do |x|
      kl = klasses[x%klasses.length]
      u = kl.new(PLAYER_TEAM, "char#{x}", 0, 0, l)
      l -= 1 if l > 1
      u
    end
    @level = Level.generate(pl)
    @x, @y = 1, 1
    @current_action = MapSelect.new(3, 3, @level)
  end
  def add_glyph(screen, x,y, highlight_squares, lit_spaces)
    screen.map.set_xy(x,y)
    return screen.map.draw_str('x') unless lit_spaces.nil? || lit_spaces.include?([x,y])
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

    strings = [
      [unit.name.capitalize, TEAM_TO_COLOR[unit.team]],
      ["#{unit.klass} (#{unit.level})"],
      [unit.health_str, unit.health_color],
      [unit.power_for_info_str],
      [unit.skill_for_info_str],
      [unit.armor_for_info_str],
      [unit.speed_for_info_str],
      [unit.weapon_name_str],
    ]
    if vs
      # combat stats - Power, Strength, Crit
      strings += [
        [unit.power_str(vs)],
        [unit.accuracy_str(vs).to_s],
        [unit.crit_str],
      ]
      strings += ["x2"] if unit.double_attack?(vs)
    end

    strings.each_with_index do |str, i|
      screen.info.set_xy(x, i)
      screen.info.draw_str(*str)
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
    screen.info.set_xy(0, 13)
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
      highlight_spaces += Path.discover_paths(c, @level, c.movement).map(&:last_point)
    end
    # lit_spaces = @level.calculate_fov(@level.units.select{|u| u.team == PLAYER_TEAM })
    lit_spaces = nil
    MAP_SIZE_X.times do |x|
      MAP_SIZE_Y.times do |y|
        add_glyph(screen,x,y, highlight_spaces, lit_spaces)
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

GS.current = PlayerTurn.new
begin
  Screen.open do |s|
    loop do
      current = GS.current
      current.execute
      current.display(s)
      current.move_to_correct_space(s)
      current.key(Curses::getch)
    end
  end
ensure
  puts $log.inspect
end
