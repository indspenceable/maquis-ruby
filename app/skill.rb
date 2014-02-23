# a skill is a modifier for a unit
# this can provide it passive abilities, activated abilites,
# stat boosts, vulnerabilities, etc.
# Basically - it's awesome.
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
  end

  def identifier
    self.class.identifier
  end

  def modifies?(sym)
    !!self.class.modifier_for(sym)
  end

  def modify(sym, caller, val)
    caller.instance_exec(val, &self.class.modifier_for(sym))
  end
end

# our example skill is "horseback"
class Horseback < Skill
  identifier :horse

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
  identifier :pegasus

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
    ws + [:swords]
  end
end

class WieldLances < Skill
  identifier :lance

  modify :weapon_skills do |ws|
    ws + [:lances]
  end
end

class WieldAxes < Skill
  identifier :axes

  modify :weapon_skills do |ws|
    ws + [:axes]
  end
end

class CastAnima < Skill
  identifier :anima

  modify :weapon_skills do |ws|
    ws + [:anima]
  end
end

class CastLight < Skill
  identifier :light

  modify :weapon_skills do |ws|
    ws + [:light]
  end
end

class CastDark < Skill
  identifier :dark

  modify :weapon_skills do |ws|
    ws + [:dark]
  end
end

class WieldBows < Skill
  identifier :bows

  modify :weapon_skills do |ws|
    ws + [:bows]
  end
end


class Farsight < Skill
  identifier :farsight

  modify :los_distance do |_|
    7
  end
end

class Armor < Skill
  identifier :armor

  modify :movement do |m|
    m - 1
  end

  modify :traits do |traits|
    traits + [:armored]
  end

  modify :constitution do |con|
    con + 2
  end
end

class Vampirism < Skill
  identifier :vampire

  modify :hit do |damage|
    heal(damage/2)
    damage
  end

  modify(:traits){ |traits| traits + [:undead] }
end

def all_skills
  rtn = []
  ObjectSpace.each_object(Class) do |s|
    rtn << s if s < Skill
  end
  rtn
end


# class MountainClimber
#   identifier :mountains

#   modify :movement_costs do |old_movement_costs|
#     old_movement_costs.merge({:mountain => 3})
#   end
# end
