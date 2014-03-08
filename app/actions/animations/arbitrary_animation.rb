class ArbitraryAnimation < Action
  def initialize(unit, text, level, &next_action)
    @unit, @text, @level, @next_action =
      unit, text, level, next_action
  end

  def draw(window)
    draw_map(window)
    draw_units(@level.units, window)
    @frame ||= 0
    @done = window.draw_rising_text(@unit.x, @unit.y, @text, 30, @frame, 2)
    @frame += 1
  end

  def key(k)
    self
  end

  def cancel
    self
  end

  def auto
    if @done
      @next_action.call
    else
      self
    end
  end
end
