require 'set'

class Level
  attr_reader :units, :log, :difficulty, :army, :goal, :map_size_x, :map_size_y
  attr_accessor :fog_of_war
  def initialize(w,h)
    @map_size_x,@map_size_y = w,h
    @units = []
    @log = []
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

  def self.evade_bonus_for_terrain
    Hash.new(0).merge({
      :forest => 20,
      :fort => 20,
    })
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

  # returns the action for whoever's turn is next.
  # also, do stuff that happens between turns.
  def finish_turn(team)
    if units.none?{ |u| u.team == COMPUTER_TEAM }
      return Planning.new(difficulty, army.tap(&:next_level!))
    end

    units.each do |u|
      if u.team == team
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
      UnitSelect.new(lord.x, lord.y, self)
    end
  end
end
