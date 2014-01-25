class Inventory < MenuAction
  def initialize(unit, level, previous_action)
    @unit, @level, @cancel_action = unit, level, previous_action
    super((0..unit.inventory.count).to_a)
  end

  def action!
    # override action!
    return cancel if @index == @unit.inventory.count
    if @unit.inventory[@index].trigger!(@unit)
      Inventory.new(@unit, @level, UnitSelect.new(@unit.x, @unit.y, @level))
    else
      self
    end
  end

  def string_and_color
    @string_and_colors ||= @unit.inventory.map do |i|
      [i.name, i.color_for(@unit), 0]
    end + [["END", RED, 0]]

  end

  def cancel
    @cancel_action
  end

  def unit_for_map_highlighting
    nil
  end

  def units_for_info_panel
    [@unit]
  end
end
