class AttackTargetSelect < MenuAction
  attr_reader :level

  def initialize unit, level, targets, path, prev_action
    @unit = unit
    @level = level
    @targets = targets
    @prev_action = prev_action
    @path = path
    super Array.new(@targets.length){:confirm}
  end

  def draw(screen)
  end

  def set_cursor(screen)
    screen.map.set_xy(@targets[@index].x, @targets[@index].y)
  end

  def units_for_info_panel
    [@unit, @targets[@index]]
  end

  def confirm
    # MoveAndAttackAttack.new(@unit, @targets[@index], @level, @path)
    AttackWeaponSelect.new(@unit, @targets[@index], @level, @path, self)
  end

  def cancel
    @prev_action
  end

  def unit_for_map_highlighting
    nil
  end
end
