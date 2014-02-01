class ConfirmMove < MenuAction
  attr_reader :level

  attr_accessor :can_undo_move

  def string_and_color
    {
      :attack => "Attack",
      :items => "Item",
      :confirm => ["End", GREEN],
      :trade => ["Trade", GREEN],
      # :cancel => ["Cancel", RED],
    }
  end

  def initialize(unit, path, level, prev_action)
    @level = level
    @unit = unit
    @prev_action = prev_action
    @path = path
    opts = []
    @start_x, @start_y = @unit.x, @unit.y
    @unit.x, @unit.y = @path.last_point
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

  def draw_special(screen)
    @path.each_but_last do |x,y|
      screen.map.set_xy(x,y)
      screen.map.draw_str('*', BLUE)
    end
    super(screen)
  end

  def confirm
    @unit.action_available = false
    UnitSelect.new(@unit.x, @unit.y, @level)
  end

  def cancel
    @unit.x, @unit.y = @start_x, @start_y
    @prev_action
  end

  def trade
    TradeTargetSelect.new(@unit, @level, friends_adjacent,@path, self)
  end

  def unit_for_map_highlighting
    nil
  end

  def items
    Inventory.new(@unit, @level, self)
  end
end
