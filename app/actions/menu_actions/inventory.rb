class Inventory < MenuAction
  def initialize(unit, level, &previous_action)
    @unit, @level, @previous_action = unit, level, previous_action
    super((0..unit.inventory.count).to_a)
    @cancel_or_end ="Cancel"
  end

  def action!
    # override action!
    return cancel if @index == @unit.inventory.count
    @did_something ||= @unit.inventory[@index].trigger!(@unit)

    if !@unit.action_available
      # If we did an action that took up their action, move on to the next unit
      @level.next_action(@unit.x, @unit.y)
    else
      self
    end
  end

  def choice_strings
    @unit.inventory.map do |i|
      i.pretty
    end + ["Cancel"]
  end

  def cancel
    @previous_action.call
  end

  def draw(window)
    draw_map(window)
    draw_all_units(window)
    window.draw_menu(choice_strings, @index)
  end
end
