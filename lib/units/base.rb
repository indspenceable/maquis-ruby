class Unit
  attr_accessor :team, :name, :x, :y, :action_available

  STATS = [
    :max_hp,
    :power,
    :skill,
    :armor,
    :speed,
    :constitution
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

  # HEALTH
  def health_str
    "#{@hp}/#{max_hp}"
  end
  def health_color
    @hp/max_hp.to_f > 0.66 ? GREEN :
      @hp / max_hp.to_f > 0.33 ? BLUE : RED
  end

  def armor_for_info_str
    "ARM: #{armor}"
  end

  def speed_for_info_str
    "SPE: #{speed} (#{effective_speed})"
  end

  # POWER
  def power_for_info_str
    weapon ? "POW: #{power} + #{weapon.power}" : "POW: NA"
  end
  def total_power
    power + weapon.power if weapon
  end
  def power_vs(vs)
    [total_power - vs.armor,0].max if weapon
  end
  def power_str(vs)
    weapon ? power_vs(vs).to_s : "NA"
  end

  def take_hit_from(op)
    damage = op.power_vs(self)
    @hp -= damage
    damage
  end

  # SKILL
  def to_hit
    weapon.to_hit + skill if weapon
  end
  def evade
    0
  end
  def accuracy(vs)
    to_hit - vs.evade if weapon
  end
  def accuracy_str(vs)
    weapon ? "#{accuracy(vs)}%" : "NA"
  end
  def skill_for_info_str
    weapon ? "HIT: #{skill} + #{weapon.to_hit}" : "HIT: NA"
  end

  # CRITICAL
  def crit_chance
    weapon.to_crit if weapon
  end
  def crit_str
    weapon ? "#{crit_chance}%" : "NA"
  end

  def weapon_slow
    [constitution - weapon.weight, 0].max if weapon
  end
  def effective_speed
    speed - (weapon ? weapon_slow : 0)
  end
  def double_attack?(vs)
    effective_speed >= vs.effective_speed + 4 if weapon
  end

  def weapon
    @weapon ||= Weapon.new("Iron Sword", 5, 90, 0, 5)
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
