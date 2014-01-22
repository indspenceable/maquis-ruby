class Unit
  attr_accessor :team, :x, :y, :action_available

  def name
    if lord?
      "Lord #{@name.capitalize}"
    else
      @name.capitalize
    end
  end

  BASE_STATS = {
    :max_hp => 20,
    :power => 3,
    :skill => 3,
    :armor => 3,
    :speed => 3,
  }
  STATS = BASE_STATS.keys

  attr_reader *STATS
  attr_reader :level, :hp, :exp

  LEVEL_UPS_FOR_LEVEL_ONE = 0

  def initialize team, name, level = 1, is_lord=false
    @team, @name = team, name
    @x, @y = 0, 0

    #ensure everyone is level 1 at least.
    level = 1 if level < 1

    @action_available = true
    STATS.each do |stat|
      # starting_stat = BASE_STATS[stat] + rand(5) - 2
      self.instance_variable_set(:"@#{stat}", starting_stats[stat])
    end
    @growths = {}
    class_growths.each do |k, (min,max)|
      @growths[k] = rand((max-min)/5)*5 + min
    end

    @hp = max_hp
    @inventory = [IronSword.new, IronLance.new, IronAxe.new].shuffle
    @level = 0
    (level + LEVEL_UPS_FOR_LEVEL_ONE - 1).times { level_up! }
    @level = level

    @is_lord = is_lord
    @exp = 0
  end

  def lord?
    @is_lord
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
    "SPE: #{speed} (#{weapon_slow})"
  end

  def can_hit?(vs)
    can_hit_range?(Path.unit_dist(self, vs))
  end
  def can_hit_range?(n)
    weapon && weapon.in_range?(n)
  end

  # POWER
  def power_for_info_str
    weapon ? "POW: #{power} + #{weapon.power}" : "POW: NA"
  end
  def total_power
    power + weapon.power if weapon
  end
  def weapon_triangle(my_type, their_type)
    {
      :swords => {
        :axes => 1,
        :lances => -1
      },
      :axes => {
        :swords => -1,
        :lances => 1,
      },
      :lances => {
        :swords => 1,
        :axes => -1,
      }
    }[my_type][their_type] || 0 rescue 0
  end
  def weapon_triangle_bonus_power(vs)
    return 0 unless weapon && vs.weapon
    weapon_triangle(weapon_type, vs.weapon_type)
  end
  def power_vs(vs)
    [total_power + weapon_triangle_bonus_power(vs) - vs.armor,0].max if weapon
  end
  def power_str(vs)
    can_hit?(vs) ? power_vs(vs).to_s : "NA"
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
  def weapon_triangle_bonus_accuracy(vs)
    weapon_triangle(weapon_type, vs.weapon_type) * 15
  end
  def accuracy(vs)
    to_hit + weapon_triangle_bonus_accuracy(vs) - vs.evade if weapon
  end
  def accuracy_str(vs)
    can_hit?(vs) ? "#{accuracy(vs)}%" : "NA"
  end
  def skill_for_info_str
    weapon ? "HIT: #{skill} + #{weapon.to_hit}" : "HIT: NA"
  end

  # CRITICAL HITS
  def crit_chance
    weapon.to_crit if weapon
  end
  def crit_str
    weapon ? "#{crit_chance}%" : "NA"
  end

  def weapon_slow
    [constitution - weapon.weight, 0].min if weapon
  end
  def effective_speed
    speed + (weapon ? weapon_slow : 0)
  end
  def double_attack?(vs)
    effective_speed >= vs.effective_speed + 4 if weapon
  end

  def weapon
    available_weapons.first
  end
  def weapon_type
    weapon.weapon_type
  end
  def available_weapons
    @inventory.select{|x| x.is_a?(Weapon) && weapon_skills.include?(x.weapon_type)}
  end
  def weapons_that_hit_at(x)
    available_weapons.select{|w| w.in_range?(x)}
  end
  def equip! weapon
    @inventory.delete(weapon)
    @inventory.unshift(weapon)
  end

  def weapon_name_str
    weapon ? weapon.name : "Unequipped"
  end

  def alive?
    @hp > 0
  end

  def heal
    @hp = max_hp
  end

  def self.create(level, *args)
    unit = self.new(*args)
    (level+3).times {|u| u.level_up!(:silent => true)}
  end

  def gain_experience n
    @exp += n
    if @exp >= 100
      @exp -= 100
      return level_up!
    end
  end

  def klass_exp_power
    3
  end

  def level_up!
    @level += 1
    stats_grown = []
    @growths.each do |stat, growth|
      if rand(100) < growth
        stats_grown << stat
        current_val = instance_variable_get(:"@#{stat}")
        instance_variable_set(:"@#{stat}", current_val + 1)
        @hp += 1 if stat == :max_hp
      end
    end
    stats_grown
  end
end

def create_class(g, k, mv, con, growths, starting_stats, weapon_skills, klass_exp_power=3)
  Class.new(Unit) do
    glyph g
    klass k
    define_method :class_growths do
      growths
    end
    define_method :starting_stats do
      starting_stats
    end
    define_method :movement do
      mv
    end
    define_method :constitution do
      con
    end
    define_method :weapon_skills do
      weapon_skills
    end
    define_method :klass_exp_power do
      klass_exp_power
    end
  end
end

%w(archer armor_knight cavalier fighter mercenary myrmidon
  pegasus_knight).each do |f|
  require "./lib/units/#{f}"
end

# Cleric = create_class('p', "Cleric", x, y, {

# }, {
#   :max_hp => 14,
#   :power => 3,
#   :skill => 2,
#   :speed => 3,
#   :armor => 1,
#   :res =>   4,
# }, [:staves])

