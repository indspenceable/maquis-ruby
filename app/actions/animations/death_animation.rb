class DeathAnimation < Action
  def initialize(unit, level, &next_action)
    @unit, @level, @next_action = unit, level, next_action
  end

  def draw(window)
    draw_map(window)
    draw_units(@level.units - [@unit], window)
    @done = window.draw_battle_animation(@unit, nil, :death, self)
  end

  def key(k)
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
