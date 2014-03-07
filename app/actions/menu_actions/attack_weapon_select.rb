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

class StaffSelect < MenuAction
  attr_reader :level

  def initialize unit, targets, level, prev_action, &next_action
    @unit = unit
    @level = level
    @targets = targets
    @prev_action = prev_action
    @next_action = next_action

    # Select from staves
    @staves = @unit.inventory.select{|s| s.is_a?(Staff) &&
      targets.any? do |t|
        unit.staff_range(s).include?(Path.unit_dist(unit, t))
      end
    }
    super((0...@staves.size).to_a)
  end

  def draw(window)
    draw_map(window)
    draw_all_units(window)
    window.draw_menu(@staves.map(&:pretty), @index)
  end

  def action!
    @next_action.call(@staves[@index])
  end

  def cancel
    @prev_action
  end

  def ok?
    @staves.any?
  end
end
