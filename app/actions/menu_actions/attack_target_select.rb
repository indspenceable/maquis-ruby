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
    window.highlight(Hash[@targets.map{|t| [[t.x, t.y], effect]}])
    window.highlight([selected_target.x, selected_target.y] => :cursor)
    # window.draw_unit_fight_compare(@unit, selected_target)
  end
end

class AttackTargetSelect < TargetSelect
  def initialize unit, level, targets, path, prev_action
    super(unit, level, targets, path, prev_action) do |t|
      AttackWeaponSelect.new(@unit, t, @level, @path, self)
    end
  end
  def effect
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
  def effect
    :blue
  end
end
