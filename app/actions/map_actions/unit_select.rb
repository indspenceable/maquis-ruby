class UnitSelect < MapAction
  attr_reader :level

  def current_unit
    @level.units.find{|c| c.x == @x && c.y == @y}
  end

  def initialize(x, y, level)
    @level = level
    @x, @y = x, y
  end
  def activate
    if current_unit && current_unit.action_available
      if current_unit.team == PLAYER_TEAM
        Move.new(@x, @y, @level)
      else
        HighlightEnemyMoves.new(current_unit, @level, self)
      end
    else
      TurnMenu.new(@level, self)
    end
  end
  def cancel
    self
    # Ahaha! Can't quit now, sucka.
  end
  def units_for_info_panel
    Array(@level.see?(@x,@y) && current_unit)
  end

  def unit_for_map_highlighting
    nil
  end

  def set_cursor(screen)
    screen.map.set_xy(@x,@y)
  end
end
