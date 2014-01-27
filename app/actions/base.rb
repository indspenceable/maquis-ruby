class Action

  def initialize
    raise "trying to initialize abstract class Action!"
  end

  #################
  # for curses play

  def display(screen)
    display_map(screen)
    display_character_info(screen)
    display_messages(screen)
    draw_special(screen)
  end

  def draw_special(screen)
  end

  # Releys on @level, #unit_for_map_highlihgting
  def display_map(screen)
    #at this point, discover what paths we can go to.
    highlight_spaces = {}
    c = unit_for_map_highlighting
    if c
      highlight_spaces = squares_to_color_for_highlighting(c)
    end
    @level.calculate_simple_fov(PLAYER_TEAM) if @level.fog_of_war
    # lit_spaces = nil
    MAP_SIZE_X.times do |x|
      MAP_SIZE_Y.times do |y|
        add_glyph(screen,x,y, highlight_spaces)
      end
    end
  end

  def squares_to_color_for_highlighting(c)
    return @squares_to_color_for_highlighting ||= begin
      movements = Path.discover_paths(c, @level, c.movement).map(&:last_point)
      movements_with_no_one_there = movements.reject do |m|
        u = @level.unit_at(*m)
        (u && u != c)
      end
      attack = []
      MAP_SIZE_X.times do |x|
        MAP_SIZE_Y.times do |y|
          attack << [x,y] if movements_with_no_one_there.any? do |_x,_y|
            c.weapons_that_hit_at(Path.dist(x, y, _x, _y)).any?
          end
        end
      end
      attack -= movements_with_no_one_there
      attack -= @level.units.select{|u| u.team == c.team }.map{|u| [u.x, u.y]}
      rtn = {}
      movements.each do |x,y|
        rtn[[x,y]] = BLUE
      end
      attack.each do |x,y|
        rtn[[x,y]] = RED
      end
      rtn
    end
  end

  # this method figures out the right glyph to draw, and draws it
  def add_glyph(screen, x, y, highlight_squares)
    screen.map.set_xy(x,y)
    # return screen.map.draw_str('x') unless lit_spaces.nil? || lit_spaces.include?([x,y])
    if @level.see?(x,y)
      c = @level.unit_at(x,y)
      if c
        color = TEAM_TO_COLOR[c.team]
        attrs = c.action_available ? 0 : Curses::A_BOLD
        attrs |= Curses::A_REVERSE if highlight_squares[[x,y]] == RED
        return screen.map.draw_str(c.glyph, color, attrs)
      end
    end

    cl = if highlight_squares.key?([x,y])
      [highlight_squares[[x,y]], Curses::A_REVERSE]
    else
      @level.see?(x,y) ? [] : [FOG_COLOR, Curses::A_DIM]
    end

    screen.map.draw_str(@level.map_to_str(x,y), *cl)
  end

  # Depends on @level, #units_for_info_panel
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

  def display_character_info_for(screen, unit, i, vs=nil)
    x = i*20

    map_strs = (@level ? "Terrain: #{@level.map(unit.x, unit.y)}" : "")
    exp_bars = ((unit.exp+5)/10)
    exp_level = ('-' * exp_bars) + ' ' * (10-exp_bars)

    strings = [
      [unit.name, TEAM_TO_COLOR[unit.team]],
      ["#{unit.klass}: #{unit.level}"],
      [map_strs],
      ["|#{exp_level}|"],
      # ["% 3d/100 xp" % unit.exp],
      ["#{unit.health_str} hp", unit.health_color],
      # [unit.power_for_info_str],
      # [unit.skill_for_info_str],
      # [unit.armor_for_info_str],
      # [unit.speed_for_info_str],
      [unit.weapon_name_str],
    ]
    if vs
      # combat stats - Power, Strength, Crit
      double_str = unit.double_attack?(vs)? "(x2)" : ""
      power_accent = unit.weapon_effectiveness(vs) == 3 ? Curses::A_BOLD : 0
      strings += [
        [''],
        [unit.weapon.name],
        [" Pow: #{unit.power_str(vs, @level, ignore_range)}#{double_str}", 0, power_accent],
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

 # uses @messages, releys on nothing.
  def display_messages(screen)
    screen.messages.clear
    screen.messages.set_xy(0,0)
    @messages.each_with_index do |message, i|
      screen.messages.set_xy(0, i)
      screen.messages.draw_str(*Array(message))
    end if @messages
  end

  def ignore_range
    false
  end

end
