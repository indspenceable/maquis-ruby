class AttackAnimation < Action
  def initialize(unit, target, damage, level, &next_action)
    @unit, @target, @damage, @level, @next_action =
      unit, target, damage, level, next_action
  end

  def draw(window)
    draw_map(window)
    draw_units(@level.units - [@unit, @target], window)
    @done = window.draw_battle_animation(@unit, @target, @damage, self)
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
