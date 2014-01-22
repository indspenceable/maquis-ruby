class ConfirmMove < MenuAction
  attr_reader :level

  def string_and_color
    {
      :attack => ["Attack", BLUE],
      :confirm => ["Move", GREEN],
      :cancel => ["Cancel", RED]
    }
  end


  def initialize(unit, path, level, prev_action)
    @level = level
    @unit = unit
    @prev_action = prev_action
    @path = path
    opts = []
    if enemies_in_range.any? && unit.weapon
      opts << :attack
    end
    opts << :confirm
    opts << :cancel
    super(opts)
    @start_x, @start_y = @unit.x, @unit.y
    @unit.x, @unit.y = @path.last_point
  end

  def units_for_info_panel
    [@unit]
  end

  def enemies_in_range
    @enemies_in_range ||= @level.units.select do |u|
      u.team != @unit.team &&
      @unit.available_weapons.any?{|w| w.in_range?(Path.dist(u.x, u.y, *@path.last_point))}
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
    MapSelect.new(@unit.x, @unit.y, @level)
  end

  def cancel
    if level.fog_of_war
      self
    else
      @unit.x, @unit.y = @start_x, @start_y
      @prev_action
    end
  end

  def unit_for_map_highlighting
    nil
  end
end
