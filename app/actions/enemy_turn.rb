EnemyMoveOption = Struct.new(:unit, :path, :target)
class EnemyTurn < Action
  attr_reader :level

  def initialize level
    @level = level
    @level.units.each{|u| u.action_available = true }
    @ai = CautiousAI.new
  end

  def auto
    my_units     = @level.units.select{|u| u.team == COMPUTER_TEAM}
    player_units = @level.units.select{|u| u.team == PLAYER_TEAM}
    current_unit = select_a_unit(my_units)
    if current_unit
      options = find_all_options_for_unit(current_unit)
      current_option = options.max_by{|o| @ai.score(o, @level) }
      execute_option(current_option)
    else
      @level.finish_turn(COMPUTER_TEAM)
    end
  end

  def draw(window)
    draw_map(window)
    draw_all_units(window)
  end

  def key(k)
    self
  end

  def select_a_unit(units)
    units.find(&:action_available)
  end

  def find_all_options_for_unit(u)
    # all the people we could attack
    all_targets = @level.units.select{|u| u.team != COMPUTER_TEAM }
    Path.discover_unblocked_paths(u, @level, u.movement).map do |p|
      x,y = p.last_point
      [EnemyMoveOption.new(u, p, nil)] + all_targets.map do |t|
        EnemyMoveOption.new(u, p, t) if hit_from?(u, t, x, y)
      end
    end.flatten.compact.shuffle # TODO remove shuffle.
  end

  def execute_option(o)
    return WalkPathAction.new(o.unit, o.path, @level) do
      mx,my = o.path.last_point
      o.unit.x, o.unit.y = o.path.last_point
      if o.target
        AttackExecutor.new(o.unit, o.target, @level) { self }
      else
        o.unit.action_available = false
        self
      end
    end
  end

  def cancel
    self
  end

  private

  def hit_from?(unit, target, x, y)
    #am in range of this unit
    d = Path.dist(x,y, target.x, target.y)
    unit.weapons_that_hit_at(d).any?
  end
end
