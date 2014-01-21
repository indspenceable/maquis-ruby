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

    draw(screen)
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
    # lit_spaces = @current_action.level.calculate_fov(@current_action.level.units.select{|u| u.team == PLAYER_TEAM })
    lit_spaces = nil
    MAP_SIZE_X.times do |x|
      MAP_SIZE_Y.times do |y|
        add_glyph(screen,x,y, highlight_spaces, lit_spaces)
      end
    end
  end

  # this method figures out the right glyph to draw, and draws it
  def add_glyph(screen, x, y, highlight_squares, lit_spaces)
    screen.map.set_xy(x,y)
    return screen.map.draw_str('x') unless lit_spaces.nil? || lit_spaces.include?([x,y])
    c = level.unit_at(x,y)
    if c
      color = TEAM_TO_COLOR[c.team]
      attrs = c.action_available ? 0 : Curses::A_BOLD
      return screen.map.draw_str(c.glyph, color, attrs)
    end

    if highlight_squares.include?([x,y])
      screen.map.draw_str(level.map[x][y], 0, Curses::A_REVERSE)
    else
      screen.map.draw_str(level.map[x][y], 0)
    end
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
