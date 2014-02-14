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

  def choice_strings
    @unit.inventory.map do |i|
      i.name
    end + [@did_something ? "End" : "Cancel"]
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
    draw_map(window)
    draw_all_units(window)
    window.draw_menu(choice_strings, @index)
  end
end
