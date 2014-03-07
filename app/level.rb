require 'set'

class Level
  attr_reader :units, :log, :difficulty, :army, :goal, :map_size_x, :map_size_y, :turn_count
  attr_accessor :fog_of_war, :primary_objective, :secondary_objectives
  def initialize(w,h)
    @map_size_x,@map_size_y = w,h
    @units = []
    @log = []
    @turn_count = 0
  end

  def army= a
    raise "level already has player army set!" if @army
    @army = a
    @units += @army.units
  end

  def difficulty= d
    raise "difficulty already set!" if @difficulty
    @difficulty = d
  end

  GOALS = [:seize_throne, :kill_enemies]
  def goal= g
    raise "Already have a goal!" if @goal
    raise "#{g} is not a recognized goal" unless GOALS.include?(g)
    @goal = g
  end

  def calculate_simple_fov(team)
    @lit = Set.new
    units.select{|u| u.team == team}.each do |u|
      los_dist = u.los_distance
      (-los_dist).upto(los_dist) do |x|
        (-los_dist).upto(los_dist) do |y|
          @lit << [u.x+x, u.y+y] if x.abs + y.abs <= los_dist
        end
      end
    end
    @lit
  end

  def lit_spaces
    @lit
  end

  def see?(x,y)
    return true unless fog_of_war
    lit_spaces.include?([x,y])
  end

  def see_path?(p)
    p.any?{|x,y| see?(x,y)}
  end

  def map(x,y)
    @map[x][y] || default_terrain rescue default_terrain
  end

  def default_terrain
    @default_terrain ||= Wall.new
  end

  def set_map(x,y,v)
    @map[x][y] = v
  end

  def map_to_str(x,y)
    self.class.terrain_sym_to_str[map(x,y)] || (raise "Oops #{map(x,y)}")
  end

  def raw_map
    @map
  end

  def fill
    @map = Array.new(@map_size_x) do |x|
      Array.new(@map_size_y) do |y|
        yield x, y
      end
    end
  end

  def lord
    units.find{|u| u.lord? }
  end

  def unit_at(x,y)
    units.find{|c| c.x == x && c.y == y}
  end

  def player_units
    units.select{ |u| u.team == PLAYER_TEAM }
  end

  def computer_units
    units.select{ |u| u.team == COMPUTER_TEAM }
  end

  def upkeep &blk
    # did anyone die?
    u = units.find{|u| !u.alive? }
    if u
      return DeathAnimation.new(u, self) do
        units.delete(u)
        if u.lord?
          # Kill our savegame.
          LordDied.new
        else
          upkeep(&blk)
        end
      end
    end

    # draw animations
    u = units.find do |u|
      u.animation_queue.any?
    end
    if u
      animation = u.animation_queue.pop
      puts "Animation: #{animation}"
    end

    u = player_units.find{|u| u.pending_exp > 0 }
    if u
      return ExperienceGain.new(u, self) do
        upkeep(&blk)
      end
    end

    # did anyone's weapons break?
    u = player_units.find do |u|
      u.weapon && u.weapon.used_up?
    end
    if u
      u.inventory.delete(u.weapon)
      u.animation_queue << "weapon broke"
      return upkeep(&blk)
    end

    blk.call
  end

  def secondary_objective_descriptions
    @secondary_objectives.map do |objective, reward|
      "#{objective.description} for #{reward.description}"
    end
  end

  # for the players turn
  def next_action(x,y)
    upkeep do
      if primary_objective.met?
        win!
      elsif player_units.none?(&:action_available)
        finish_turn(PLAYER_TEAM)
      else
        UnitSelect.new(x,y,self)
      end
    end
  end

  def win!
    @secondary_objectives.each do |objective, reward|
      puts "Checking #{objective}"
      if objective.met?
        puts "met it!"
        reward.apply!(army)
      end
    end
    army.next_level!(difficulty)
    Planning.new(difficulty+1, army)
  end

  # returns the action for whoever's turn is next.
  # also, do stuff that happens between turns.
  def finish_turn(team)
    return win! if primary_objective.met?

    units.each do |u|
      if u.team != team
        u.action_available = true
        if map(u.x, u.y) == :fort
          u.heal(u.max_hp / 10)
        end
        u.countdown_buffs!
      end
    end

    if team == PLAYER_TEAM
      EnemyTurn.new(self)
    else
      @turn_count += 1
      next_action(lord.x, lord.y)
    end
  end
end
