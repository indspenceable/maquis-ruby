class TargetSelect < MenuAction
  def initialize unit, level, targets, path, prev_action, &next_action
    @unit = unit
    @level = level
    @targets = targets
    @prev_action = prev_action
    @path = path
    @next_action = next_action
    super Array.new(@targets.length){:confirm}
  end

  def units_for_info_panel
    [@unit, @targets[@index]]
  end

  def confirm
    @next_action.call(@targets[@index])
  end

  def cancel
    @prev_action
  end

  def display(window)
    draw_map(window)
    window.highlight(Hash[@targets.map{|t| [[t.x, t.y], color]}])
  end
end

class AttackTargetSelect < TargetSelect
  def initialize unit, level, targets, path, prev_action
    super(unit, level, targets, path, prev_action) do |t|
      AttackWeaponSelect.new(@unit, t, @level, @path, self)
    end
  end
  def color
    :red
  end
end

class TradeTargetSelect < TargetSelect
  def initialize unit, level, targets, path, prev_action
    super(unit, level, targets, path, prev_action) do |t|
      Trade.new(unit, t, self) do
        unit.action_available = false
        UnitSelect.new(unit.x, unit.y, level)
      end
    end
  end
  def color
    :blue
  end
end
