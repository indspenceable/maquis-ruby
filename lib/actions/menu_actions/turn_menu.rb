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
