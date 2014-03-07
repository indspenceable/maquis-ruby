class TargetSelect < MenuAction
  def initialize unit, level, targets, effect, prev_action, &next_action
    @unit = unit
    @level = level
    @targets = targets
    @prev_action = prev_action
    @next_action = next_action
    @effect = effect
    super Array.new(@targets.length){:confirm}
  end

  def selected_target
    @targets[@index]
  end

  def units_for_info_panel
    [@unit, @targets[@index]]
  end

  def confirm
    @next_action.call(@targets[@index])
  end

  def key(k)
    super(case k
    when KEYS[:left]
      KEYS[:up]
    when KEYS[:right]
      KEYS[:down]
    else
      k
    end)
  end

  def cancel
    @prev_action
  end

  def draw(window)
    draw_map(window)
    draw_all_units(window)
    window.highlight(Hash[@targets.map{|t| [[t.x, t.y], @effect]}])
    window.highlight([selected_target.x, selected_target.y] => :cursor)
    # window.draw_unit_fight_compare(@unit, selected_target)
  end
end

class AttackTargetSelect < TargetSelect
  def initialize unit, level, targets, prev_action
    super(unit, level, targets, :red, prev_action) do |t|
      AttackExecutor.new(unit, t, level) do
        level.next_action(unit.x, unit.y)
      end
    end
  end

  def draw(window)
    super(window)
    window.compare_units(@unit, @targets[@index])
  end
end

class TradeTargetSelect < TargetSelect
  def initialize unit, level, targets, prev_action
    super(unit, level, targets, :blue, prev_action) do |t|
      Trade.new(unit, t, self) do
        unit.action_available = false
        level.next_action(unit.x, unit.y)
      end
    end
  end
end
