class Unit
  STATS = [
    :max_hp,
    :power,
    :skill,
    :armor,
    :speed,
    :resistance,
  ]
  attr_reader *STATS, :constitution, :exp_level, :hp, :klass
  attr_accessor :team, :x, :y, :action_available, :current_level

  def initialize *args
    raise "Can't initialize a Unit. Create a PlayerUnit or an Enemy instead."
  end

  def buff!(identifier, charges, max_charges=nil)
    buff = @buffs.find{ |x| x.identifier == identifier }
    if buff
      buff.charges = [buff.charges + charges, max_charges].compact.min
    else
      @buffs << Skill.by_name(identifier).new(self, charges)
    end
  end

  def debuff(identifier, charges=nil)
    buff = @buffs.find{ |x| x.identifier == identifier }
    if buff
      if charges && charges > buff.charges
        buff.charges -= charges
        true
      else
        @buffs.delete(buff)
        true
      end
    end
  end

  def config
    self.class.config
  end

  def affinity_to_color
    @@affinities ||= {}
    @@affinities[@klass] ||= begin
      p,m = 255, 125
      case config[@klass]['affinity']
      when nil
        [255, p, p, p]
      when 'light'
        [255, m, m, p]
      when 'light_light'
        [255, m, p, m]
      when 'light_dark'
        [255, p, p, m]
      when 'dark'
        [255, p, m, m]
      when 'dark_light'
        [255, p, m, p]
      when 'dark_dark'
        [255, m, m, m]
      end
    end
  end

  def countdown_buffs!
    @buffs.each(&:tick)
    @buffs.reject!(&:expired?)
  end

  def clear_buffs!
    @buffs = []
  end

  def pretty
    pretty_name + " (#{@exp_level})"
  end

  def pretty_name
    config[@klass]['pretty']
  end

  def class_skills
    @@skills ||= {}
    @@skills[@klass] ||= config[@klass]['skills'].map do |s|
      Skill.by_name(s).new
    end
  end

  def animation_for(anim)
    "#{klass}_#{anim}".to_sym
  end

  def skills
    class_skills + @buffs
  end

  # HEALTH
  def health_str
    "#{@hp}/#{max_hp}"
  end

  def health_color
    @hp/max_hp.to_f > 0.66 ? GREEN :
      @hp / max_hp.to_f > 0.33 ? BLUE : RED
  end

  def health_for_info_str
    "#{health_str} hp #{strength_string(:max_hp)}"
  end

  def armor_for_info_str
    "ARM: #{armor} #{strength_string(:armor)}"
  end

  def resistance_for_info_str
    "RES: #{resistance} #{strength_string(:resistance)}"
  end

  def speed_for_info_str
    "SPE: #{speed} #{strength_string(:speed)}"
  end

  def terrain
    @current_level.map(x,y) if @current_level
  end

  def terrain_armor_bonus
    @current_level.map(x,y).armor_bonus * terrain_multiplier
  end

  def terrain_evade_bonus
    @current_level.map(x,y).evade_bonus * terrain_multiplier
  end

  def adjusted_armor(weapon)
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

  def accessible_range
    # find our longest range, then get all numbers from 0 up to that number
    # which we can hit.
    max_range = available_weapons.map(&:range).map(&:max).max || 0
    max_range.times.map(&:succ).select{ |x| available_weapons.any?{|w| w.range.include?(x) } }
  end

  # POWER
  def power_for_info_str
    "POW: #{power} #{strength_string(:power)}"
  end

  def weapon_triangle(my_type, their_type)
    {
      'swords' => {
        'axes' => 1,
        'lances' => -1
      },
      'axes' => {
        'swords' => -1,
        'lances' => 1,
      },
      'lances' => {
        'swords' => 1,
        'axes' => -1,
      },
      'anima' => {
        'light' => 1,
        'dark' => -1
      },
      'light' => {
        'anima' => -1,
        'dark' => 1,
      },
      'dark' => {
        'anima' => 1,
        'light' => -1,
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
    weapon.hit(vs)
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
    effective_speed * 2
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
    "SKL: #{skill} #{strength_string(:skill)}"
  end

  # CRITICAL HITS
  def crit_chance
    if weapon
      weapon.to_crit + (skill/2) + critical_bonus
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
    effective_speed >= vs.effective_speed + 4 if weapon && !weapon.used_up?
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
    weapon.type if weapon
  end

  def available_weapons
    @inventory.select{|x| x.is_a?(Weapon) && can_wield?(x)}
  end

  def can_wield?(weapon)
    weapon_skills.include?(weapon.type)
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

  def terrain_multiplier
    1
  end

  def critical_bonus
    0
  end

  def kill(target)
    #nothing
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

  # stats are adjusted by skills
  modifiable(STATS + [
    :traits,
    :movement_costs,
    :weapon_skills,
    :los_distance,
    :movement,
    :hit,
    :terrain_multiplier,
  ])
end

