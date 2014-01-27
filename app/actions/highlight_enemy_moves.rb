class HighlightEnemyMoves < MapAction
  def initialize(unit, level, prev)
    @level = level
    @unit = unit
    @prev = prev
    @x, @y = unit.x, unit.y
  end

  def units_for_info_panel
    [
      @unit,
      @level.unit_at(@x,@y)
    ].compact.uniq
  end

  def unit_for_map_highlighting
    @unit
  end

  def cancel
    @prev
  end

  def activate
    @prev
  end

  def draw_special(_);end

  def set_cursor(screen)
    screen.map.set_xy(@x, @y)
  end
end
