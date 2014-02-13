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
    @level.finish_turn(COMPUTER_TEAM)
  end

  def draw(window)
    draw_map(window)
    draw_all_units(window)
  end

  def auto
    execute
  end

  def key(k)
  end

  def next_unit!
    begin
      @unit.action_available = false if @unit
      @unit = @my_units.pop
    end until @unit.nil? || possible_targets.any?
    @path = @target = nil
  end

  def move_and_attack
    # first, determine the target unit...
    @unit.x, @unit.y = *@path.last_point
    if @target
      unit, target = @unit, @target
      next_unit!
      displayed_anything = true
      AttackExecutor.new(unit, target, @level) { self }
    else
      @unit.action_available = false
      next_unit!
      self
    end
  end

  def attack_unit
  end

  def units_for_info_panel
    [@unit]
  end

  def cursor_xy
    case
    when @path && @level.see?(*@path.last_point)
      @path.last_point
    when @unit && @level.see?(@unit.x, @unit.y)
      [@unit.x, @unit.y]
    else
      nil
    end
  end

  private

  def lord
    @lord ||= @level.lord
  end

  def distance_from_path_to_lord(p)
    @lord_paths ||= Path.discover_paths(lord, @level, 1000, :ignore)
    @distance_cache ||= {}
    #@distance_cache[p] ||= Path.find(lord, *p.last_point, @level, 100, :ingore).length
    @distance_cache[p] ||= @lord_paths.find{|x| x.last_point == p.last_point}.length
    @distance_cache[p]
  end

  def choose_target
    ts = possible_targets
    @target = ts.find do |u|
      @unit.power_vs(u) > u.hp
    end
    @target ||= ts.inject do |u1, u2|
      if u1.hp - @unit.power_vs(u1) > u2.hp - @unit.power_vs(u2)
        u1
      else
        u2
      end
    end
    if @target
      @path = reachable_paths.find {|p| hit_from?(@target, *p.last_point) }
      @path = Path.new(@unit.x, @unit.y, @level) unless @path
    else
      @path = Path.new(@unit.x, @unit.y, @level)
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
