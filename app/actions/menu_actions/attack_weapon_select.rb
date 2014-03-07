class AttackWeaponSelect < MenuAction
  attr_reader :level

  def initialize unit, targets, level, prev_action
    @unit = unit
    @level = level
    @targets = targets
    @prev_action = prev_action

    @available_weapons = @targets.map do |t|
      @unit.weapons_that_hit_at(Path.unit_dist(unit, t))
    end.flatten.uniq
    super((0...@available_weapons.size).to_a)
  end

  def draw(window)
    draw_map(window)
    draw_all_units(window)
    window.draw_menu(@available_weapons.map(&:pretty), @index)
  end

  def key *args
    equip_selected_weapon!
    rtn = super(*args)
    equip_selected_weapon!
    rtn
  end

  def equip_selected_weapon!
    @unit.equip!(@available_weapons[@index])
  end

  def action!
    AttackTargetSelect.new(@unit, @level, @targets.select{|t| @unit.can_hit?(t)}, self)
  end

  def cancel
    @prev_action
  end
end
