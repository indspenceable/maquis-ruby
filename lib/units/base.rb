class Unit
  attr_accessor :team, :name, :x, :y, :action_available
  def initialize team, name, x, y
    @team, @name, @x, @y = team, name, x, y
    @hp = max_hp
    @action_available = true
  end

  def self.glyph c
    define_method(:glyph){ c }
  end
  def self.klass c
    define_method(:klass){ c }
  end

  def health_str
    "#{@hp}/#{max_hp}"
  end
  def health_color
    GREEN
  end
  def power_vs(vs)
    [power - vs.armor,0].max
  end
  def take_hit(damage)
    @hp -= damage
    damage
  end

  def accuracy_vs(vs)
    "75%"
  end
  def crit_chance
    "2%"
  end
  def double_attack?(vs)
    speed >= vs.speed + 4
  end

  def alive?
    @hp > 0
  end

  def self.stats hsh
    hsh.each do |stat,value|
      define_method(stat) {
        value
      }
    end
  end
end

class Archer < Unit
  glyph ?a
  klass "Archer"
  stats power: 9,
    speed: 10,
    armor: 0,
    max_hp: 20,
    movement: 5
end
class ArmorKnight < Unit
  glyph ?A
  klass "Armor Knight"
  stats power: 15,
    speed: 2,
    armor: 6,
    max_hp: 20,
    movement: 4
end
class Cavalier < Unit
  glyph ?C
  klass "Cavalier"
  def speed
    8
  end
    stats power: 13,
    speed: 7,
    armor: 3,
    max_hp: 20,
    movement: 7
end
