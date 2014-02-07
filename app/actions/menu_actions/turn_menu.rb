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
    @level.finish_turn(PLAYER_TEAM)
  end

  def units_for_info_panel
    []
  end

  def display(window)
    @prev_action.display(window)
    window.draw_menu(@choices, @index)
  end
end
