class ExperienceGain < Action
  def initialize(unit, level, &next_action)
    @unit, @level, @next_action = unit, level, next_action
    @current_exp = @unit.exp
    @target_exp = @unit.exp + @unit.pending_exp
    @delay = 60
  end

  def auto
    if @delay > 0
      self
    else
      @unit.apply_exp_gain
      @next_action.call
    end
  end

  def draw(window)
    draw_map(window)
    draw_units(@level.units, window)
    window.draw_exp_meter(@current_exp)
    if @current_exp == @target_exp
      @delay -= 1
    else
      @current_exp += 1
    end
  end

  def key(x)
    self
  end
end
