class Screen
  attr_reader :map, :messages, :info, :full
  attr_reader :win
  def self.open
    Curses::init_screen
    begin
      Curses::cbreak
      Curses::noecho
      Curses::refresh
      Curses::start_color
      Curses.ESCDELAY=200

      # INIT colors
      Curses::init_pair(BLUE, Curses::COLOR_BLUE, Curses::COLOR_BLACK)
      Curses::init_pair(RED, Curses::COLOR_RED, Curses::COLOR_BLACK)
      Curses::init_pair(GREEN, Curses::COLOR_GREEN, Curses::COLOR_BLACK)
      Curses::init_pair(YELLOW, Curses::COLOR_YELLOW, Curses::COLOR_BLACK)
      Curses::init_pair(FOG_COLOR, Curses::COLOR_BLACK, Curses::COLOR_WHITE)

      raise "Must give a block!" unless block_given?
      yield Screen.new
    ensure
      Curses::close_screen
    end
  end
  def initialize
      @win = Curses::stdscr
      @win.keypad(true)
      @map      = Region.new(0, 0, MAP_SIZE_X, MAP_SIZE_Y)
      @info     = Region.new(MAP_SIZE_X + 1, 0,
        Curses::cols-MAP_SIZE_X-1, MAP_SIZE_Y)
      @messages = Region.new(0, MAP_SIZE_Y+1,
        Curses::cols, Curses::lines-MAP_SIZE_Y+1)
      @full     = Region.new(0, 0, Curses::cols, Curses::lines)
  end

  def draw_char_at(x, y, c, highlight_squares)
    map.set_xy(x,y)
    color = TEAM_TO_COLOR[c.team]
    attrs = c.action_available ? 0 : Curses::A_BOLD
    attrs |= Curses::A_REVERSE if highlight_squares[[x,y]] == RED
    map.draw_str(c.glyph, color, attrs)
  end

  def draw_terrain(x,y, tile, highlight_squares, seen)
    map.set_xy(x,y)
    cl = if highlight_squares.key?([x,y])
      [highlight_squares[[x,y]], Curses::A_REVERSE]
    elsif seen
      []
    else
      [FOG_COLOR, Curses::A_DIM]
    end
    map.draw_str(Level.terrain_sym_to_str[tile], *cl)
  end

  def display_character_info(u1, u2, ignore_range)
    info.clear
    enemies = false
    if u1
      enemies = u2 && u1.team != u2.team
      display_character_info_for(u1, 0, enemies && u2, ignore_range)
    end
    if u2
      display_character_info_for(u2, 1, enemies && u1, ignore_range)
    end
  end

  def show_trade(u1, u2, highlighted_item)
    full.clear

    [u1, u2].map do |u|
      [u.name] + u.inventory.map do |i|
        if i == highlighted_item
          "* #{i.name}"
        else
          "  #{i.name}"
        end
      end
    end.each_with_index do |c, x|
      c.each_with_index do |str, i|
        full.set_xy(x*20, i)
        full.draw_str(*str)
      end
    end
  end

  def extended_character_info(unit)
    character_stats = [
      [unit.name, TEAM_TO_COLOR[unit.team]],
      ["#{unit.klass}: #{unit.exp_level}"],
      ["% 3d/100 xp" % unit.exp],
      ["#{unit.health_str} hp", unit.health_color],
      [unit.power_for_info_str],
      [unit.skill_for_info_str],
      [unit.armor_for_info_str],
      [unit.speed_for_info_str],
      [unit.resistance_for_info_str],
      [unit.weapon_name_str],
      ["#{unit.constitution}"],
      [unit.traits.map(&:to_s).join(', ')],
      [unit.instance_variable_get(:@skills).map(&:identifier).map(&:to_s).join(',')]
    ]

    character_inventory = unit.inventory.map do |item|
      eq_str = if item == unit.weapon
        "*"
      else
        " "
      end
      "#{eq_str}#{item.name}"
    end

    full.clear

    character_stats.each_with_index do |str, i|
      full.set_xy(2, i)
      full.draw_str(*str)
    end

    character_inventory.each_with_index do |str, i|
      full.set_xy(20, i)
      full.draw_str(*str)
    end
  end

  def draw_messages(ms)
    messages.clear
    messages.set_xy(0,0)
    ms.each_with_index do |message, i|
      messages.set_xy(0, i)
      messages.draw_str(*Array(message))
    end
  end

  def display_character_info_for(unit, i, vs, ignore_range)
    x = i*20

    map_strs = "Terrain: #{unit.terrain}"
    exp_bars = ((unit.exp+5)/10)
    exp_level = ('-' * exp_bars) + ' ' * (10-exp_bars)

    strings = [
      [unit.name, TEAM_TO_COLOR[unit.team]],
      ["#{unit.klass}: #{unit.exp_level}"],
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
        [" Pow: #{unit.power_str(vs, ignore_range)}#{double_str}", 0, power_accent],
        [" Hit: #{unit.accuracy_str(vs, ignore_range).to_s}"],
        ["Crit: #{unit.crit_str}"],
      ]
      strings << ["+", GREEN] if unit.weapon_triangle(unit.weapon_type, vs.weapon_type) == 1
      strings << ["-", RED] if unit.weapon_triangle(unit.weapon_type, vs.weapon_type) == -1
    end

    strings.each_with_index do |str, i|
      info.set_xy(x, i)
      info.draw_str(*str)
    end
  end
end
