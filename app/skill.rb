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

    def action?
      @activate
    end

    def target(t=nil)
      if t
        raise unless VALID_TARGETS.include?(t)
        @target = t
      else
        @target
      end
    end

    def range(r=nil)
      if r
        @range = r
      else
        @range
      end
    end

    def activate &blk
      @activate = blk
    end

    def activate!(*args)
      @activate.call(*args)
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

  def target
    self.class.target
  end

  def range
    self.class.range
  end

  def activate!(*args)
    self.class.activate!(*args)
  end

  def action?
    self.class.action?
  end
end

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
  identifier 'horse'

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
  identifier 'pegasus'

  modify :movement do |m|
    m + 2
  end

  modify :traits do |traits|
    traits + [:mounted, :flying]
  end

  modify :movement_costs do |old_movement_costs|
    Hash.new(1).merge({:wall => 999})
  end
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


class Farsight < Skill
  identifier 'farsight'

  modify :los_distance do |_|
    7
  end
end

class Perform < Skill
  identifier 'perform'

  target :friends
  range (1..2)

  activate do |me, target, level|
    target.buff!('empower', 1)
    me.gain_experience(10)
  end

  def effect
    :blue
  end
end

class Empower < Buff
  identifier 'empower'
  modify :power do |p|
    p + 1
  end
end

class Poison < Buff
  identifier 'poison'
  def tick
    @target.lose_life(@charges)
    super
  end
end

class Healing < Skill
  identifier 'healing'
  target :friends
  range 1

  activate do |me, target, level|
    target.heal(me.power*4)
    me.gain_experience(10)
  end

  def effect
    :blue
  end
end
