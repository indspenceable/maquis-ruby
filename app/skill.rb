# a skill is a modifier for a unit
# this can provide it passive abilities, activated abilites,
# stat boosts, vulnerabilities, etc.
# Basically - it's awesome.

VALID_TARGETS = [:friends, :foes, :all_units, :empty]

class Skill
  class << self
    def identifier i=nil
      if i
        @identifier = i
      else
        return @identifier
      end
    end

    def modifier_for(sym)
      @modifiers ||= {}
      @modifiers[sym]
    end

    def modify(sym, &blk)
      @modifiers ||= {}
      @modifiers[sym] = blk
    end

    def by_name(name)
      rtn = ObjectSpace.each_object(Class).find do |s|
        s < Skill && s.identifier == name
      end
      raise "Couldn't find skill with name: #{name}" unless rtn
      return rtn
    end

    # define an action
    def action(&activate)
      @action = activate
    end

    def my_action
      @action
    end
  end

  def identifier
    self.class.identifier
  end

  def pretty
    identifier.to_s
  end

  def modifies?(sym)
    !!self.class.modifier_for(sym)
  end

  def modify(sym, caller, val)
    caller.instance_exec(val, &self.class.modifier_for(sym))
  end

  def action?
    !!self.class.my_action
  end

  def act(*args)
    self.class.my_action.call(*args)
  end
end

# A buff is a temporary skill.
class Buff < Skill
  attr_accessor :charges
  def pretty
    "#{self.class.name}(#{@charges})"
  end

  def initialize(target, charges)
    @target = target
    @charges = charges
  end

  def tick
    @charges -= 1
  end

  def expired?
    @charges <= 0
  end
end

# our example skill is "horseback"
class Horseback < Skill
  identifier 'horseback'

  modify :movement do |m|
    m + 2
  end

  modify :traits do |traits|
    traits + [:mounted]
  end

  modify :movement_costs do |old_movement_costs|
    old_movement_costs.merge({:forest => 3, :mountain => 999})
  end
end

class PegasusRider < Skill
  identifier 'pegasus_rider'

  modify :movement do |m|
    m + 2
  end

  modify :traits do |traits|
    traits + [:mounted, :flying]
  end

  modify :movement_costs do |old_movement_costs|
    Hash.new(1).merge({:wall => 999})
  end

  # no longer get terrain bonuses though.
  modify :terrain_multiplier do |v|
    0
  end
end

class WieldStaves < Skill
  identifier 'staves'
  # TODO implement
  action 'staff', :units, friends_at_range(:all){ |m,t,l|
    current_range = Path.unit_dist(m,t)
    # check that I have a staff that hits that range
    # check that I have a staff that would hit them
    m.inventory.any? do |i|
      i.is_a?(Staff) &&
      i.valid_target?(t) &&
      m.staff_range.include?(current_range)
    end
  } do |me, target, level|
    # # find the targets
    # target.action_available = true
    # me.gain_experience(10)
    StaffSelect.new do |staff|
      staff.activate!(me, target, level)
      me.gain_experience(10)
      me.action_available = false
      level.next_action(me.x, me.y)
    end
  end
end

class WieldWands < Skill
  identifier 'wands'
  # TODO implement. Copy WieldStaves
  # this is the same logic, only w/ 'wands' and 'enemies'
end

class WieldSwords < Skill
  identifier 'swords'

  modify :weapon_skills do |ws|
    ws + ["swords"]
  end
end

class WieldLances < Skill
  identifier 'lances'

  modify :weapon_skills do |ws|
    ws + ["lances"]
  end
end

class WieldAxes < Skill
  identifier 'axes'

  modify :weapon_skills do |ws|
    ws + ["axes"]
  end
end

class CastAnima < Skill
  identifier 'anima'

  modify :weapon_skills do |ws|
    ws + ["anima"]
  end
end

class CastLight < Skill
  identifier 'light'

  modify :weapon_skills do |ws|
    ws + ["light"]
  end
end

class CastDark < Skill
  identifier 'dark'

  modify :weapon_skills do |ws|
    ws + ["dark"]
  end
end

class WieldBows < Skill
  identifier 'bows'

  modify :weapon_skills do |ws|
    ws + ["bows"]
  end
end

class LayTraps < Skill
  # TODO
  identifier 'traps'
end

class CommandAura < Skill
  identifier 'command_aura'
  #TODO implement.
end

class StrategistAura < Skill
  identifier 'strategist_aura'
  #TODO implement
end

class ProtectionAura < Skill
  identifier 'protection_aura'
  #TODO implement
end

class Rage < Skill
  identifier 'rage'
  #TODO IMPLEMENT.
end

class Berserk < Skill
  identifier 'berserking'
  modify :kill do
    buff!('bloodlust', 2)
  end
end

class Bloodlust < Buff
  identifier 'bloodlust'

  modify :power do |p|
    p+5
  end
end

class CriticalBoost < Skill
  identifier 'critical_boost'
  modify :critical_bonus do |c|
    c+15
  end
end

class GreatShield < Skill
  identifier 'great_shield'
  # TODO implement.
end

#TODO this should just be promotion bonuses, not a skill.
class DefenseBoost < Skill
  identifier 'defense_boost'
  modify :armor do |a|
    a + 5
  end
end

#Ditto
class KnaveStats < Skill
  identifier 'knave_stats'
  modify :armor do |a|
    a + 3
  end

  modify :power do |p|
    p + 3
  end
end

class EvadeBoost < Skill
  identifier 'evade_boost'
  modify :evade do |a|
    a + 15
  end
end

class PowerBoost < Skill
  identifier 'power_boost'
  modify :power do |a|
    a + 5
  end
end

class LongRangeShot < Skill
  identifier 'long_range_shot'
  # TODO
end

class Parry < Skill
  identifier 'parry'
  # TODO
end

class Scry < Skill
  identifier 'scry'
  # TODO
end

class Navigate < Skill
  identifier 'navigate'
  # TODO
end

class Looter < Skill
  identifier 'looter'
  # TODO
end

class Bombs < Skill
  identifier 'bombs'
  # TODO
end

class Backstab < Skill
  identifier 'backstab'
  # TODO ???
end

class Entrap < Skill
  identifier 'entrap'
  # TODO
end

class BloodMagic < Skill
  identifier 'blood_magic'
  # TODO give the "mark of the beast" buff, which eats life but boosts magic power.
end

class StaffAffinity < Skill
  identifier 'staff_affinity'
  # TODO
end

class Blink < Skill
  identifier 'blink'
  # TODO
end

class Teleport < Skill
  identifier 'teleport'
  # TODO
end

class Summon < Skill
  identifier 'summon'
  # TODO
end

class Necromancy < Skill
  identifier 'necromancy'
  modify :kill do |k|
    #TODO
    k
  end
end

class TerrainMaster < Skill
  identifier 'terrain'
  modify :terrain_multiplier do |v|
    2
  end

  #TODO this should also make you not trigger harmful terrain.
end

class Steal < Skill
  identifier 'steal'
  # TODO
end

class Chests < Skill
  identifier 'chests'
  # TODO
end

class Farsight < Skill
  identifier 'farsight'

  modify :los_distance do |d|
    d+2
  end
end

class Perform < Skill
  identifier 'perform'

  action do |unit, others, level, old|
    targets = others.select do |o|
      o.team == unit.team &&
      !o.action_available &&
      Path.unit_dist(unit, o) == 1
    end
    TargetSelect.new(unit, level, targets, :blue, old) do |target|
      target.action_available = true
      unit.gain_experience(10)
      unit.action_available = false
      level.next_action(unit.x, unit.y)
    end
  end
end

class Play < Skill
  identifier 'play'

  action do |unit, others, level, old|
    targets = others.select do |o|
      o.team == unit.team &&
      !o.action_available &&
      (1..2).include?(Path.unit_dist(unit, o))
    end
    TargetSelect.new(unit, level, targets, :blue, old) do |target|
      target.action_available = true
      unit.gain_experience(10)
      unit.action_available = false
      level.next_action(unit.x, unit.y)
    end
  end
end

class Dance < Perform
  identifier 'dance'
  #TODO make this real.
  # range 1..5
end

class MutlitargetWands < Skill
  identifier 'multitarget_wands'
  #TODO implement.
end


class Poison < Buff
  identifier 'poison'
  def tick
    @target.lose_life(@charges)
    super
  end
end
