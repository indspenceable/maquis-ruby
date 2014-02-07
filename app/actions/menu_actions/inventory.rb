class Inventory < MenuAction
  def initialize(unit, level, previous_action)
    @unit, @level, @previous_action = unit, level, previous_action
    super((0..unit.inventory.count).to_a)
    @did_something = false
    @cancel_or_end ="Cancel"
  end

  def action!
    # override action!
    return cancel if @index == @unit.inventory.count
    @did_something ||= @unit.inventory[@index].trigger!(@unit)

    if !@unit.action_available
      # If we did an action that took up their action, move on to the next unit
      UnitSelect.new(@unit.x, @unit.y, @level)
    else
      self
    end
  end

  def string_and_color
    @unit.inventory.map do |i|
      [i.name, i.color_for(@unit), 0]
    end + [[@did_something ? "End" : "Cancel", RED, 0]]
  end

  def cancel
    if @did_something
      @unit.action_available = false
      UnitSelect.new(@unit.x, @unit.y, @level)
    else
      @previous_action
    end
  end

  def unit_for_map_highlighting
    nil
  end

  def units_for_info_panel
    [@unit]
  end

  def draw(window)
  end
end
