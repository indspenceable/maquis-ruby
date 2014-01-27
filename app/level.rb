require 'set'

class Level
  include PermissiveFieldOfView
  attr_reader :units, :log, :difficulty, :army, :goal
  attr_accessor :fog_of_war
  def initialize(w,h)
    @w,@h = w,h
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

  def armor_bonus_at(x,y)
    {
      :forest => 1,
      :fort => 2,
    }[map(x,y)] || 0
  end

  def evade_bonus_at(x,y)
    {
      :forest => 20,
      :fort => 20,
    }[map(x,y)] || 0
  end

  GOALS = [:seize_throne, :kill_enemies]
  def goal= g
    raise "Already have a goal!" if @goal
    raise "#{g} is not a recognized goal" unless GOALS.include?(g)
    @goal = g
  end

  def calculate_fov(units)
    @lit = []
    units.each do |u|
      do_fov( u.x, u.y, 5 )
    end
    @lit
  end

  def calculate_simple_fov(team)
    @lit = Set.new
    units.select{|u| u.team == team}.each do |u|
      (-3).upto(3) do |x|
        (-3).upto(3) do |y|
          @lit << [u.x+x, u.y+y] if x.abs + y.abs <= 3
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
    @map[x][y] || :wall rescue :wall
  end

  def map_to_str(x,y)
    {
      :plains => ' ',
      :mountain => '^',
      :forest => '7',
      :fort => '#',
      :wall => 'x',
    }[map(x,y)] || (raise "Oops #{map(x,y)}")
  end

  def raw_map
    @map
  end

  def blocked?(x,y)
    @map[x][y] == :wall
  end

  def light(x,y)
    @lit << [x,y]
  end

  def fill
    @map = Array.new(@w) do |x|
      Array.new(@h) do |y|
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
        if map(u.x, u.y) == '#'
          u.heal(u.max_hp / 10)
        end
      end
    end

    if team == PLAYER_TEAM
      EnemyTurn.new(self)
    else
      UnitSelect.new(lord.x, lord.y, self)
    end
  end
end
