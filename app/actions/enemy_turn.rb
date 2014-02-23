require './app/ai'
EnemyMoveOption = Struct.new(:unit, :path, :target)



class EnemyTurn < Action
  attr_reader :level

  def initialize level
    @level = level
    @level.units.each{|u| u.action_available = true }
    @ai = CautiousAI.new
  end

  def auto
    my_units        = @level.units.select{|u| u.team == COMPUTER_TEAM}
    player_units    = @level.units.select{|u| u.team == PLAYER_TEAM}
    @current_unit ||= begin
      u = select_a_unit(my_units)
      @mx, @my = u.x, u.y if u
      u
    end
    if @current_unit
      if @scores
        return self if @scores.values.any?{|v| v.nil? }
        current_option = @options.max_by{|o| @scores[o] }
        @scores = @current_unit = nil
        execute_option(current_option)
      else
        @options = find_all_options_for_unit(@current_unit)
        @scores = {}
        @options.each{|o| @scores[o] = nil}
        prio = Thread.current.priority
        @options.each do |o|
          Thread.new do
            @scores[o] = @ai.score(o, @level)
          end
        end
        self
      end
    else
      @level.finish_turn(COMPUTER_TEAM)
    end
  end

  def draw_real(window)
    draw_map(window)
    draw_all_units(window)
  end

  def draw(window)
    if @current_unit
      @current_unit.at(@mx, @my) do
        draw_real(window)
      end
    else
      draw_real(window)
    end
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
