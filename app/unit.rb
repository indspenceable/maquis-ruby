require 'pry'
class Unit
  attr_accessor :team, :x, :y, :action_available, :current_level

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

  BASE_STATS = {
    :max_hp => 15,
    :power => 1,
    :skill => 1,
    :armor => 0,
    :speed => 0,
    :resistance => 0,
  }

  attr_reader *STATS

  attr_reader :exp_level, :hp, :exp, :klass

  def self.config
    @config ||= YAML.load(File.read('./units.yml'))
  end
  def config
    self.class.config
  end

  def class_growths
    config[@klass]['growths']
  end

  def starting_stats
    BASE_STATS.merge({
      :constitution => config[@klass]['con'] + rand(5)-2
    })
  end

  def skills
    @@skills ||= {}
    @@skills[@klass] ||= config[@klass]['skills'].map do |s|
      Skill.by_name(s).new
    end
  end

  def self.random_class
    config.keys.select do |k|
      config[k]['basic']
    end.shuffle.pop
  end

  LEVEL_UPS_FOR_LEVEL_ONE = 5

  def initialize klass, team, name, exp_level = 1, is_lord=false, average=false
    @klass = klass
    @team, @name = team, name
    @x, @y = 0, 0

    #ensure everyone is exp_level 1 at least.
    exp_level = 1 if exp_level < 1

    @action_available = true
    STATS.each do |stat|
      self.instance_variable_set(:"@#{stat}", BASE_STATS[stat] || starting_stats[stat])
      raise "#{stat} starting value undefined for #{@klass}!" unless starting_stats[stat]
      raise "#{stat} growth undefined for #{@klass}!" unless class_growths[stat] || stat==:constitution
    end

    @growths = {}
    if average
      class_growths.each do |k, val|
        (val/2)+20
        @growths[k] = val
      end
    else
      class_growths.each do |k, val|
        min,max = 20, val+20
        @growths[k] = rand((max-min)/5)*5 + min
      end
    end

    # lords have universally improved growths. Look out, myrmidon lord skill stat...
    if is_lord
      @growths.keys.each do |k|
        @growths[k] += (rand(3)+1)*5
      end
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

    @exp_level = 0
    if average
      jump_to_exp_level(exp_level)
    else
      (exp_level + LEVEL_UPS_FOR_LEVEL_ONE - 1).times { exp_level_up! }
    end
    @exp_level = exp_level

    @is_lord = is_lord
    @exp = 0
  end

  def lord?
    @is_lord
  end

  # HEALTH
  def health_str
    "#{@hp}/#{max_hp}"
  end

  def health_color
    @hp/max_hp.to_f > 0.66 ? GREEN :
      @hp / max_hp.to_f > 0.33 ? BLUE : RED
  end

  def strength_string(pct)
    case
    when pct < 30
      "LOW"
    when pct < 50
      "MED"
    when pct < 80
      "HIGH"
    else
      "!!!"
    end
  end


  def health_for_info_str
    "#{health_str} hp #{strength_string(@growths[:max_hp])}"
  end

  def armor_for_info_str
    "ARM: #{armor} #{strength_string(@growths[:armor])}"
  end

  def resistance_for_info_str
    "RES: #{resistance} #{strength_string(@growths[:resistance])}"
  end

  def speed_for_info_str
    "SPE: #{speed} #{strength_string(@growths[:speed])}"
  end

  def terrain
    @current_level.map(x,y) if @current_level
  end

  def terrain_armor_bonus
    Level.armor_bonus_for_terrain[terrain]
  end

  def terrain_evade_bonus
    Level.evade_bonus_for_terrain[terrain]
  end

  def adjusted_armor(weapon)
    # puts "terrain armor is #{terrain_armor_bonus} and weapon is #{weapon.power} and resist = #{resistance} and armor = #{armor}"
    terrain_armor_bonus + if weapon.magic?
      resistance
    else
      armor
    end
  end

  def adjusted_evade
    evade + terrain_evade_bonus
  end

  def can_hit?(vs)
    can_hit_range?(Path.unit_dist(self, vs))
  end
  def can_hit_range?(n)
    weapon && weapon.in_range?(n)
  end

  # POWER
  def power_for_info_str
    "POW: #{power} #{strength_string(@growths[:power])}"
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

  def weapon_triangle_bonus_string(vs)
    if weapon_triangle(weapon_type, vs.weapon_type) > 0
      "+"
    elsif weapon_triangle(weapon_type, vs.weapon_type) < 0
      "-"
    end
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

  def at(x,y,&blk)
    ox, oy = @x, @y
    @x, @y = x, y
    rtn = blk.call
    @x, @y = ox, oy
    rtn
  end

  def power_vs(vs)
    # binding.pry
    [
      power +
      (weapon.power + weapon_triangle_bonus_power(vs)) * weapon_effectiveness(vs) -
      vs.adjusted_armor(weapon),
    0].max if weapon
  end
  def power_str(vs, at_range)
    if (at_range ? can_hit_range?(at_range) : can_hit?(vs))
      power_vs(vs).to_s
    else
      "NA"
    end
  end

  def hit(vs, multiplier)
    damage = vs.lose_life(power_vs(vs)*multiplier)
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

  def accuracy(vs)
    to_hit + weapon_triangle_bonus_accuracy(vs) - vs.adjusted_evade if weapon
  end

  def accuracy_str(vs, at_range)
    if (at_range ? can_hit_range?(at_range) : can_hit?(vs))
      "#{accuracy(vs)}%"
    else
      "NA"
    end
  end
  def skill_for_info_str
    "SKILL: #{skill} #{strength_string(@growths[:skill])}"
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

  def double_attack_str(vs)
    if double_attack?(vs)
      "x2"
    else
      ""
    end
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

  def self.create(exp_level, *args)
    unit = self.new(*args)
    (exp_level+3).times {|u| u.exp_level_up!(:silent => true)}
  end

  def gain_experience n
    @exp += n
    if @exp >= 100
      @exp -= 100
      return exp_level_up!
    end
  end

  def exp_level_up!
    @exp_level += 1
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

  def jump_to_exp_level(exp_level)
    @growths.each do |stat, growth|
      amount_to_grow = growth*exp_level/100
      current_val = instance_variable_get(:"@#{stat}")
      instance_variable_set(:"@#{stat}", current_val + amount_to_grow)
      @hp += amount_to_grow if stat == :max_hp
    end
    @exp_level = exp_level
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
        skills.inject(self.__send__(original_method_name, *args)) do |val, skill|
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

  def pretty_name
    config[@klass]['pretty']
  end

  def animation_for(anim)
    "#{klass}_#{anim}".to_sym
  end

  def summary
    "#{name} (#{pretty_name}: #{exp_level})"
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

