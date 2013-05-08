class MenuAction
  def initialize choices
    @choices = choices
    @index = 0
  end
  def key(c)
    if c == KEYS[:down]
      @index += 1
    elsif c == KEYS[:up]
      @index -=1
    elsif c == KEYS[:accept]
      return action!
    end
    @index = @index % @choices.length
    self
  end
  def draw(screen)
    @choices.each_with_index do |choice, i|
      screen.info.set_xy(0, 17+i)
      screen.info.draw_str *string_and_color[choice]
    end
  end
  def set_cursor(screen)
    screen.info.set_xy(0, 17+@index)
  end
  def action!
    send @choices[@index]
  end
end

class TurnMenu < MenuAction
  attr_reader :level
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
