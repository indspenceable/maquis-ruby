class AttackWeaponSelect < MenuAction
  attr_reader :level

  def initialize unit, target, level, path, prev_action
    @unit = unit
    @level = level
    @target = target
    @prev_action = prev_action
    @path = path

    @available_weapons = @unit.weapons_that_hit_at(Path.dist(@target.x, @target.y, *@path.last_point))
    super((0...@available_weapons.size).to_a)
  end

  def units_for_info_panel
    [@unit, @target]
  end

  def draw(window)
    draw_map(window)
    draw_all_units(window)
    window.draw_menu(@available_weapons.map(&:name), @index)
  end

  def key *args
    rtn = super
    equip_selected_weapon!
    rtn
  end

  def equip_selected_weapon!
    @unit.equip!(@available_weapons[@index])
  end

  def action!
    AttackExecutor.new(@unit, @target, @level) do
      @level.next_action(@unit.x, @unit.y)
    end
  end

  def cancel
    @prev_action
  end
end
