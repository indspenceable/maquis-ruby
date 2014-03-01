class PlanningMenu < MenuAction
  def initialize(unit, planning)
    @unit, @planning = unit, planning
    super(unit.promotes)
  end

  def action!
    @unit.promote(@choices[@index])
    @planning
  end

  def cancel
    @planning
  end

  def draw(window)
    window.draw_menu(@choices, @index)
  end
end
