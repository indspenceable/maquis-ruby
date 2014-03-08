class Aura
  def self.by_name(name)
    rtn = ObjectSpace.each_object(Class).find do |s|
      s < Aura && s.identifier == name
    end
    raise "Couldn't find aura with name: #{name}" unless rtn
    return rtn
  end

  def should_add?(unit)
    Path.unit_dist(unit,@host) <= self.range && (unit.team == @host.team) == same_team?
  end

  def same_team?
    true
  end

  def add_member(unit)
    unless unit.aura_membership.include?(self)
      unit.aura_membership << self
      on_enter(unit)
    end
  end

  def remove_member(unit)
    if unit.aura_membership.include?(self)
      unit.aura_membership.delete(self)
      on_exit(unit)
    end
  end

  def initialize(host)
    @host = host
  end

  def range
    raise "unimplemented!"
  end

  def skills
    raise "Unimplemented!"
  end

  def on_enter(unit)
  end

  def on_exit(unit)
  end
end

class PowerAura < Aura
  def self.identifier
    'power'
  end

  def range
    5
  end

  def skills
    @skills ||= [PowerBoost.new]
  end

  def on_enter(unit)
    unit.animation_queue << "Enter power aura!"
  end

  def on_exit(unit)
    unit.animation_queue << "Leave power aura!"
  end
end
