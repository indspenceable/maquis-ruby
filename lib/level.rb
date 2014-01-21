class Level
  include PermissiveFieldOfView
  attr_reader :map, :units, :log, :difficulty, :army
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
  def blocked?(x,y)
    @map[x][y] == '#'
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

  def self.generate(player_army, difficulty)
    generator = [LevelGenerator::KillEnemies.new].sample
    generator.generate(player_army, difficulty)
  end
end
