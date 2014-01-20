require 'curses'

KEYS = ARGV[0] == 'vi' ? {
  :left => 'h',
  :right => 'l',
  :down => 'j',
  :up => 'k',
  :cancel => 27,
  :accept => 'a',
} : {
  :left => 'a',
  :right => 'd',
  :down => 's',
  :up => 'w',
  :cancel => 27,
  :accept => ' ',
}

$log = []

BLUE = 1
RED = 2
GREEN = 3

TEAM_TO_COLOR = {
  0 => GREEN,
  1 => RED
}

require './lib/game_runner'

class CursesDisplay
  include GameRunner

  def initialize
    setup
  end

  def add_glyph(screen, x,y, highlight_squares, lit_spaces)
    screen.map.set_xy(x,y)
    return screen.map.draw_str('x') unless lit_spaces.nil? || lit_spaces.include?([x,y])
    c = @current_action.level.unit_at(x,y)
    if c
      color = TEAM_TO_COLOR[c.team]
      attrs = c.action_available ? 0 : Curses::A_BOLD
      return screen.map.draw_str(c.glyph, color, attrs)
    end

    # c = @current_action.unit_for_map_highlighting
    # if c && Path.shortest_between(c.x,c.y, x, y, @current_action.level, c.movement)
    if highlight_squares.include?([x,y])
      screen.map.draw_str(@current_action.level.map[x][y], 0, Curses::A_REVERSE)
    else
      screen.map.draw_str(@current_action.level.map[x][y], 0)
    end
    # dim if it's out of range.
  end

  def display_character_info_for(screen, unit, i, vs=nil)
    x = i*20

    strings = [
      [unit.name.capitalize, TEAM_TO_COLOR[unit.team]],
      ["#{unit.klass} (#{unit.level})"],
      ["% 3d/100" % unit.exp],
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
        [''],
        [unit.power_str(vs)],
        [unit.accuracy_str(vs).to_s],
        [unit.crit_str],
      ]
      strings << ["x2"] if unit.double_attack?(vs)
      strings << ["+", GREEN] if unit.weapon_triangle(unit.weapon_type, vs.weapon_type) == 1
      strings << ["-", RED] if unit.weapon_triangle(unit.weapon_type, vs.weapon_type) == -1
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

  def draw_current_action(screen)
    @current_action.draw(screen)
  end

  def finish_display
    Curses::refresh
  end

  #TODO this is not ideal but it lives here so fuck it.
  def key(c)
    (('a'..'z').to_a + [' ']).each do |str|
      c = str if str.unpack('C')[0] == c
    end
    if c == KEYS[:cancel]
      @current_action = @current_action.cancel
    else
      @current_action = @current_action.key(c)
    end
  end
end


class GS
  def self.current
    @current_state
  end
  def self.current= gs
    @current_state = gs
  end
end


GS.current = CursesDisplay.new
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

