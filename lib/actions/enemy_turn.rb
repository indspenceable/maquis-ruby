class EnemyTurn < Action
  attr_reader :level

  def initialize level
    @level = level
    @level.units.each{|u| u.action_available = true }

    @my_units = @level.units.select{|u| u.team == COMPUTER_TEAM}
    next_unit!
  end

  def execute
    while true
      return end_turn unless @unit
      if @path
        rtn_me = true if @path && @level.see_path?(@path)
        rtn = move_and_attack
        return rtn if rtn_me
      else
        choose_target
      end
      return self if @path && @level.see_path?(@path)
    end
  end

  def end_turn
    @level.units.each{|u| u.action_available = true }
    #@unit = first_unit = @level.units.find{|u| u.team == PLAYER_TEAM}
    UnitSelect.new(@level.lord.x, @level.lord.y, @level)
  end
  def draw_special(screen)
    @path.each do |x,y|
      if @level.see?(x,y)
        screen.map.set_xy(x,y)
        screen.map.draw_str('*', RED)
      end
    end if @path
  end

  def key(c)
    self
  end

  def next_unit!
    @unit = @my_units.pop
    @path = @target = nil
  end

  def move_and_attack
    # first, determine the target unit...
    @unit.x, @unit.y = *@path.last_point
    if @target
      unit, target = @unit, @target
      next_unit!
      displayed_anything = true
      AttackExecutor.new(unit, target, @level, self)
    else
      @unit.action_available = false
      next_unit!
      self
    end
  end

  def attack_unit
  end

  def unit_for_map_highlighting
    nil
  end

  def units_for_info_panel
    [@unit]
  end

  def set_cursor(screen)
    return screen.map.set_xy(*@path.last_point) if @path && @level.see?(*@path.last_point)
    return screen.map.set_xy(@unit.x, @unit.y) if @unit && @level.see?(@unit.x, @unit.y)
    return screen.map.set_xy(level.lord.x, level.lord.y)
  end

  private

  def lord
    @lord ||= @level.lord
  end

  def distance_from_path_to_lord(p)
    @lord_paths ||= Path.discover_paths(lord, @level, 1000, true)
    @distance_cache ||= {}
    #@distance_cache[p] ||= Path.find(lord, *p.last_point, @level, 100, true).length
    @distance_cache[p] ||= @lord_paths.find{|x| x.last_point == p.last_point}.length
    @distance_cache[p]
  end

  def choose_target
    ts = possible_targets
    @target = ts.find do |u|
      @unit.power_vs(u, @level) > u.hp
    end
    @target ||= ts.inject do |u1, u2|
      if u1.hp - @unit.power_vs(u1, @level) > u2.hp - @unit.power_vs(u2, @level)
        u1
      else
        u2
      end
    end
    if @target
      @path = reachable_paths.find {|p| hit_from?(@target, *p.last_point) }
    else
      @path = reachable_paths.inject do |p1,p2|
        if distance_from_path_to_lord(p1) < distance_from_path_to_lord(p2)
          p1
        else
          p2
        end
      end
    end
    self
  end

  def hit_from?(u,x,y)
    #am in range of this unit
    d = Path.dist(x,y, u.x, u.y)
    @unit.weapons_that_hit_at(d).any?
  end

  def reachable_paths
    Path.discover_unblocked_paths(@unit, @level, @unit.movement).shuffle
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

  def cancel
    self
  end
end
