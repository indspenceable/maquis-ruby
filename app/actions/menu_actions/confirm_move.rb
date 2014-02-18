class ConfirmMove < MenuAction
  attr_reader :level

  attr_accessor :can_undo_move

  def initialize(unit, path, level, &prev_action)
    @level = level
    @unit = unit
    @prev_action = prev_action
    @path = path
    opts = []
    if enemies_in_range.any? && unit.weapon
      opts << :attack
    end
    if friends_adjacent.any?
      opts << :trade
    end
    opts << :items
    opts << :confirm
    super(opts)
  end

  def units_for_info_panel
    [@unit]
  end

  def enemies_in_range
    @enemies_in_range ||= @level.units.select do |u|
      u.team != @unit.team &&
      @level.see?(u.x, u.y) &&
      @unit.available_weapons.any?{|w| w.in_range?(Path.unit_dist(@unit, u))}
    end
  end

  def friends_adjacent
    @friends_adjacent ||= @level.units.select do |u|
      (u.team == @unit.team) && (Path.unit_dist(u, @unit) == 1)
    end
  end

  def attack
    AttackTargetSelect.new(@unit, @level, enemies_in_range, @path, self)
  end

  def draw(window)
    draw_map(window)
    draw_all_units(window)
    # window.draw_path(@path)
    window.draw_menu(@choices, @index)
  end

  def confirm
    @unit.action_available = false
    UnitSelect.new(@unit.x, @unit.y, @level)
  end

  def cancel
    @prev_action.call
  end

  def trade
    TradeTargetSelect.new(@unit, @level, friends_adjacent,@path, self)
  end

  def items
    Inventory.new(@unit, @level) { self }
  end
end
