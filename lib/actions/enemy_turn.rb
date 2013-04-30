class EnemyTurn
  def initialize level
    @level = level
    @level.units.each{|u| u.action_available = true }

    @my_units = @level.units.select{|u| u.team == COMPUTER_TEAM}
    next_unit
  end

  def execute
    return end_turn unless @unit
    if @moved
      attack_unit
    elsif @path
      move_unit
    else
      choose_target
    end

    self
  end

  def end_turn
    @level.units.each{|u| u.action_available = true }
    first_unit = @level.units.find{|u| u.team == PLAYER_TEAM}
    MapSelect.new(first_unit.x, first_unit.y, @level)
  end
  def draw(screen)
    @path.each do |x,y|
      screen.map.set_xy(x,y)
      screen.map.draw_str('*', GREEN)
    end if @path
  end

  def key(c)
    self
  end

  def next_unit
    @unit = @my_units.pop
    @moved = @path = @target = nil
  end

  def move_unit
    # first, determine the target unit...
    @unit.x, @unit.y = *@path.last_point
    next_unit unless @target
  end

  def attack_unit
  end

  def unit_for_map_highlighting
    @unit
  end

  def units_for_info_panel
    [@unit]
  end

  def set_cursor(screen)
    return screen.map.set_xy(*@path.last_point) if @path
    return screen.map.set_xy(@unit.x, @unit.y) if @unit
  end

  private

  def choose_target
    ts = possible_targets
    @target = ts.find do |u|
      @unit.power_vs(u) > u.life
    end
    @target ||= ts.inject do |u1, u2|
      if u1.life - @unit.power_vs(u1) > u2.life - @unit.power_vs(u2)
        u1
      else
        u2
      end
    end
    if @target
      @path = reachable_paths.find {|p| hit_from(@target, *p.last_point) }
    else
      @path = reachable_paths.shuffle.first
    end
  end

  def hit_from?(u,x,y)
    #am in range of this unit
    d = Path.dist(x,y, u.x, u.y)
    @unit.weapons_that_hit_at(d).any?
  end

  def reachable_paths
    Path.discover_paths(@unit, @level, @unit.movement)
  end

  def possible_targets
    # find all spaces we can go to
    all_targets = @level.units.select{|u| u.team != COMPUTER_TEAM }

    all_targets.select do |u|
      reachable_paths.map(&:last_point).any? do |x,y|
        hit_from?(u, x, y)
      end
    end
  end
end
