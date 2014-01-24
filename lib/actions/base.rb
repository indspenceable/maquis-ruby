class Action

  def initialize
    raise "trying to initialize abstract class MenuAction!"
  end

  #################
  # for curses play

  def display(screen)
    display_map(screen)
    display_character_info(screen)
    display_messages(screen)
    draw_special(screen)
  end

  def display_messages(screen)
    screen.messages.clear
  end

  def display_map(screen)
    #at this point, discover what paths we can go to.
    highlight_spaces = []
    c = unit_for_map_highlighting
    if c
      highlight_spaces += Path.discover_paths(c, level, c.movement).map(&:last_point)
    end
    lit_spaces = level.calculate_simple_fov(PLAYER_TEAM) if level.fog_of_war
    # lit_spaces = nil
    MAP_SIZE_X.times do |x|
      MAP_SIZE_Y.times do |y|
        add_glyph(screen,x,y, highlight_spaces, lit_spaces)
      end
    end
  end

  # this method figures out the right glyph to draw, and draws it
  def add_glyph(screen, x, y, highlight_squares, lit_spaces)
    screen.map.set_xy(x,y)
    space_is_lit = lit_spaces.nil? || lit_spaces.include?([x,y])
    # return screen.map.draw_str('x') unless lit_spaces.nil? || lit_spaces.include?([x,y])
    if space_is_lit
      c = level.unit_at(x,y)
      if c
        color = TEAM_TO_COLOR[c.team]
        attrs = c.action_available ? 0 : Curses::A_BOLD
        return screen.map.draw_str(c.glyph, color, attrs)
      end
    end

    cl = space_is_lit ? [] : [FOG_COLOR, Curses::A_DIM]
    if highlight_squares.include?([x,y])
      screen.map.draw_str(level.map(x,y), GREEN, Curses::A_REVERSE)
    else
      screen.map.draw_str(level.map(x,y), *cl)
    end
  end

  def display_character_info_for(screen, unit, i, vs=nil)
    x = i*20

    map_strs = @level ? "(#{@level.map(unit.x, unit.y)})" : ""

    strings = [
      [unit.name, TEAM_TO_COLOR[unit.team]],
      ["#{unit.klass}: #{unit.level} #{map_strs}"],
      ["% 3d/100 xp" % unit.exp],
      ["#{unit.health_str} hp", unit.health_color],
      [unit.power_for_info_str],
      [unit.skill_for_info_str],
      [unit.armor_for_info_str],
      [unit.speed_for_info_str],
      [unit.weapon_name_str],
    ]
    if vs
      # combat stats - Power, Strength, Crit
      double_str = unit.double_attack?(vs)? "(x2)" : ""
      strings += [
        [''],
        [" Pow: #{unit.power_str(vs, @level, ignore_range)}#{double_str}", 0, 0],
        [" Hit: #{unit.accuracy_str(vs, @level, ignore_range).to_s}"],
        ["Crit: #{unit.crit_str}"],
      ]
      strings << ["+", GREEN] if unit.weapon_triangle(unit.weapon_type, vs.weapon_type) == 1
      strings << ["-", RED] if unit.weapon_triangle(unit.weapon_type, vs.weapon_type) == -1
    end

    strings.each_with_index do |str, i|
      screen.info.set_xy(x, i)
      screen.info.draw_str(*str)
    end
  end

  def ignore_range
    false
  end

  def display_character_info(screen)
    screen.info.clear
    u1, u2 = units_for_info_panel
    enemies = false
    if u1
      enemies = u2 && u1.team != u2.team
      display_character_info_for(screen, u1, 0, enemies && u2)
    end
    if u2
      display_character_info_for(screen, u2, 1, enemies && u1)
    end
  end
end
