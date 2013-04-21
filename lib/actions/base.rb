class Action
  def display_character_info_for(screen, unit, i, vs=nil)
    x = i*10

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
      screen.info.draw_str(unit.power_vs(vs))
      screen.info.set_xy(x,5)
      screen.info.draw_str(unit.accuracy_vs(vs))
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
end
