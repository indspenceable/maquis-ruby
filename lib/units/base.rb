class Unit
  attr_accessor :team, :name, :x, :y, :action_available

  STATS = [
    :max_hp,
    :power,
    :skill,
    :armor,
    :speed
  ]

  attr_reader *STATS

  def initialize team, name, x, y, stats
    @team, @name, @x, @y = team, name, x, y
    @action_available = true
    STATS.each do |stat|
      self.instance_variable_set(:"@#{stat}", stats[stat])
    end
    @hp = max_hp
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
    @hp/max_hp.to_f > 0.66 ? GREEN :
      @hp / max_hp.to_f > 0.33 ? BLUE : RED
  end

  def power_vs(vs)
    [power - vs.armor,0].max
  end
  def power_str(vs)
    power_vs(vs).to_s
  end

  def take_hit_from(op)
    damage = op.power_vs(self)
    @hp -= damage
    damage
  end

  def to_hit
    85 + skill
  end
  def evade
    2
  end

  def accuracy(vs)
    to_hit - evade
  end

  def accuracy_str(vs)
    "#{accuracy(vs)}%"
  end
  def crit_chance
    2
  end
  def crit_str
    "#{crit_chance}%"
  end

  def effective_speed
    speed
  end
  def double_attack?(vs)
    effective_speed >= vs.effective_speed + 4
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

def create_class(g, k, mv)
  Class.new(Unit) do
    glyph g
    klass k
    stats :movement => mv
  end
end
Archer = create_class('a', "Archer", 5)
Cavalier = create_class('c', "Cavalier", 9)
ArmorKnight = create_class('k', "Knight", 4)
Mercenary = create_class('m', "Mercenary", 7)
Myrmidon = create_class('s', "Myrmidon", 7)
