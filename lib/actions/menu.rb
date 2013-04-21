class MenuAction
  def initialize choices
    @choices = choices
    @index = 0
  end
  def key(c)
    if c == 'j'
      @index += 1
    elsif c == 'k'
      @index -=1
    elsif c == 'a'
      return send @choices[@index]
    end
    @index = @index % @choices.length
    self
  end
  def draw(screen)
    @choices.each_with_index do |choice, i|
      screen.info.set_xy(0, 13+i)
      screen.info.draw_str *string_and_color[choice]
    end
  end
  def set_cursor(screen)
    screen.info.set_xy(0, 13+@index)
  end
end

class TurnMenu < MenuAction
  def initialize(level, prev_action)
    @level = level
    @prev_action = prev_action
    super([:end_turn, :cancel, :quit])
  end
  def cancel
    @prev_action
  end
  def end_turn
    @level.units.each{|u| u.action_available = true }
    EnemyTurn.new(@level)
  end
  def string_and_color
    {
      :end_turn => ["End Turn", GREEN],
      :quit => ["Quit Game", RED],
      :cancel => ["Cancel", RED]
    }
  end
  def unit_for_map_highlighting
    nil
  end
  def units_for_info_panel
    []
  end
end
