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

  def display(window)
    draw_map(window)
    window.highlight(squares_to_color_for_highlighting(@unit))
  end

  def cancel
    @prev
  end

  def activate
    @prev
  end
end
