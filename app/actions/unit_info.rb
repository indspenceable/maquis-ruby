class UnitInfo < Action
  def initialize(unit, team, prev_action)
    @index = team.index(unit)
    @team = team
    @prev_action = prev_action
  end

  def key(c)
    if c == KEYS[:down]
      @index += 1
    elsif c == KEYS[:up]
      @index -= 1
    end

    @index = @index % @team.count
    self
  end

  def cancel

    @prev_action
  end

  def display(screen)
    unit = @team[@index]
    character_stats = [
      [unit.name, TEAM_TO_COLOR[unit.team]],
      ["#{unit.klass}: #{unit.level}"],
      ["% 3d/100 xp" % unit.exp],
      ["#{unit.health_str} hp", unit.health_color],
      [unit.power_for_info_str],
      [unit.skill_for_info_str],
      [unit.armor_for_info_str],
      [unit.speed_for_info_str],
      [unit.resistance_for_info_str],
      [unit.weapon_name_str],
    ]

    character_inventory = unit.inventory.map do |item|
      eq_str = if item == unit.weapon
        "*"
      else
        " "
      end
      "#{eq_str}#{item.name}"
    end

    screen.full.clear

    character_stats.each_with_index do |str, i|
      screen.full.set_xy(2, i)
      screen.full.draw_str(*str)
    end

    character_inventory.each_with_index do |str, i|
      screen.full.set_xy(20, i)
      screen.full.draw_str(*str)
    end
  end

  def set_cursor(screen)
    screen.full.set_xy(0,0)
  end
end
