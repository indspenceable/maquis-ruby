require 'pry'

class Unit
  attr_accessor :team, :x, :y, :action_available

  def name
    if lord?
      "Lord #{@name.capitalize}"
    else
      @name.capitalize
    end
  end

  STATS = [
    :max_hp,
    :power,
    :skill,
    :armor,
    :speed,
    :resistance,
    :constitution,
  ]

  attr_reader *STATS

  attr_reader :level, :hp, :exp

  def growth_pct(stat)
    @growths[stat]
  end

  LEVEL_UPS_FOR_LEVEL_ONE = 3

  def initialize team, name, level = 1, is_lord=false, average=false
    @team, @name = team, name
    @x, @y = 0, 0

    #ensure everyone is level 1 at least.
    level = 1 if level < 1

    @action_available = true
    STATS.each do |stat|
      self.instance_variable_set(:"@#{stat}", starting_stats[stat])
      raise "#{stat} starting value undefined for #{self.class.name}!" unless starting_stats[stat]
      raise "#{stat} growth undefined for #{self.class.name}!" unless class_growths[stat] || stat==:constitution
    end

    @growths = {}
    if average
      class_growths.each do |k, (min,max)|
        @growths[k] = (max-min)/2 + min
      end
    else
      class_growths.each do |k, (min,max)|
        @growths[k] = rand((max-min)/5)*5 + min
      end
    end

    # lords have universally improved growths. Look out, myrmidon lord skill stat...
    if is_lord
      @growths.keys.each do |k|
        @growths[k] += rand(3)*5
      end
    end

    @skills = []
    starting_skills.each do |s|
      learn_skill(s)
    end

    @hp = max_hp
    @inventory = [
      IronSword.new,
      IronLance.new,
      IronAxe.new,
      IronBow.new,
      Lightning.new,
      Flux.new,
      Fire.new,].shuffle
    @inventory = available_weapons

    @level = 0
    if average
      jump_to_level(level)
    else
      (level + LEVEL_UPS_FOR_LEVEL_ONE - 1).times { level_up! }
    end
    @level = level

    @is_lord = is_lord
    @exp = 0
  end

  def learn_skill(skill)
    skill.class.modifiers.each do |m|
      unless self.class.modifiable_methods.include?(m)
        raise "#{skill} modifies non-method #{m} (not in#{self.class.modifiable_methods})!"
      end
    end
    @skills.each do |s|
      if s.conflicts?(skill.identifier) || skill.conflicts?(s.identifier)
        raise "#{skill} conflicts with #{s}"
      end
    end
    raise "Already have #{skill}" if @skills.any?{|s| s.identifier == skill.identifier}
    @skills << skill
  end

  def lord?
    @is_lord
  end

  def self.glyph c
    define_method(:klass_glyph){ c }
  end

  def glyph
    @is_lord ? 'l' : klass_glyph
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

  def resistance_for_info_str
    "RES: #{resistance}"
  end

  def speed_for_info_str
    "SPE: #{speed}"
  end

  def adjusted_armor(level, weapon)
    level.armor_bonus_at(x, y) + if weapon.magic?
      resistance
    else
      armor
    end
  end

  def adjusted_evade(level)
    evade + level.evade_bonus_at(x,y)
  end

  def can_hit?(vs)
    can_hit_range?(Path.unit_dist(self, vs))
  end
  def can_hit_range?(n)
    weapon && weapon.in_range?(n)
  end

  # POWER
  def power_for_info_str
    weapon ? "POW: #{power}" : "POW: NA"
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
      },
      :anima => {
        :light => 1,
        :dark => -1
      },
      :light => {
        :anima => -1,
        :dark => 1,
      },
      :dark => {
        :anima => 1,
        :light => -1,
      }

    }[my_type][their_type] || 0 rescue 0
  end
  def weapon_triangle_bonus_power(vs)
    return 0 unless weapon && vs.weapon
    weapon_triangle(weapon_type, vs.weapon_type)
  end

  def weapon_effectiveness(vs)
    # this accounts for things like:
    # Bows are good against fliers
    # Rapiers are good against armored and horseback
    # etc
    if (weapon.targets & vs.traits).any?
      3
    else
      1
    end
  end

  def power_vs(vs, level)
    [[
      power +
      (weapon.power + weapon_triangle_bonus_power(vs)) * weapon_effectiveness(vs) -
      vs.adjusted_armor(level, weapon),
    0].max, vs.hp].min if weapon
  end
  def power_str(vs, level, at_range)
    if (at_range ? can_hit_range?(at_range) : can_hit?(vs))
      power_vs(vs, level).to_s
    else
      "NA"
    end
  end

  def hit(vs, level, multiplier)
    damage = vs.lose_life(power_vs(self, level)*multiplier)
    damage
  end

  def lose_life damage
    @hp -= damage
    if hp < 0
      @hp = 0
    end
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
  def accuracy(vs, level)
    to_hit + weapon_triangle_bonus_accuracy(vs) - vs.adjusted_evade(level) if weapon
  end
  def accuracy_str(vs, level, at_range)
    if (at_range ? can_hit_range?(at_range) : can_hit?(vs))
      "#{accuracy(vs, level)}%"
    else
      "NA"
    end
  end
  def skill_for_info_str
    weapon ? "HIT: #{skill}" : "HIT: NA"
  end

  # CRITICAL HITS
  def crit_chance
    if weapon
      [weapon.to_crit + skill/2].max
    end
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
    @inventory.select{|x| x.is_a?(Weapon) && can_wield?(x)}
  end

  def can_wield?(weapon)
    weapon_skills.include?(weapon.weapon_type)
  end

  def weapons_that_hit_at(x)
    available_weapons.select{|w| w.in_range?(x)}
  end

  def equip! weapon
    @inventory.delete(weapon)
    @inventory.unshift(weapon)
  end

  def inventory
    @inventory.reject!(&:used_up?)
    @inventory
  end

  def weapon_name_str
    weapon ? weapon.name : "Unequipped"
  end

  def alive?
    @hp > 0
  end

  def heal(amount=max_hp)
    @hp += amount
    @hp = max_hp if @hp > max_hp
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

  def level_up!
    @level += 1
    stats_grown = []
    @growths.each do |stat, growth|
      if rand(100) < growth
        stats_grown << stat
        current_val = instance_variable_get(:"@#{stat}")
        instance_variable_set(:"@#{stat}", current_val + 1)
        # increase current hp when max_hp rises.
        @hp += 1 if stat == :max_hp
      end
    end
    stats_grown
  end

  def jump_to_level(level)
    @growths.each do |stat, growth|
      amount_to_grow = growth*level/100
      current_val = instance_variable_get(:"@#{stat}")
      instance_variable_set(:"@#{stat}", current_val + amount_to_grow)
      @hp += amount_to_grow if stat == :max_hp
    end
    @level = level
  end

  # base stats

  def movement
    5
  end

  def los_distance
    3
  end

  def movement_costs
    Path.default_movement_costs
  end

  def weapon_skills
    []
  end

  def traits
    []
  end

  def self.modifiable_methods
    @@modifiable_methods ||= []
  end

  def self.modifiable(*methods)
    @@modifiable_methods ||= []
    Array(methods).flatten.each do |meth|
      @@modifiable_methods << meth
      original_method_name = "original_#{meth}"
      alias_method original_method_name, meth
      define_method(meth) do |*args|
        @skills.inject(self.__send__(original_method_name, *args)) do |val, skill|
          unless skill.is_a?(Skill)
            raise "Skill #{skill.inspect}/#{skill.class} in #{self.class} is not a skill!"
          end
          if skill.modifies?(meth)
            skill.modify(meth, self, val)
          else
            val
          end
        end
      end
    end
  end

  # stats are adjusted by skills
  modifiable(STATS + [
    :traits,
    :movement_costs,
    :weapon_skills,
    :los_distance,
    :movement,
    :hit
  ])
end

def create_class(g, k, growths, starting_stats, starting_skills)
  Class.new(Unit) do
    glyph g
    klass k

    define_method :class_growths do
      growths
    end
    define_method :starting_stats do
      starting_stats
    end
    define_method :starting_skills do
      starting_skills
    end
  end
end

Dir.glob('./app/units/*').each do |f|
  require f
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

