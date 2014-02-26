class Consumable
  def initialize(charges)
    @charges = charges
  end

  def trigger!(unit)
    @charges -= 1
    unit.action_available = false
    consume(unit)
  end

  def consume
    raise "no implementation of #consume for #{self.class.name}"
  end

  def used_up?
    @charges <= 0
  end

  def pretty
    name
  end
end

class SkillToken < Consumable
  def initialize(skill)
    @skill = skill
    super(1)
  end

  def name
    "Skill token #{@skill.identifier}"
  end

  def consume(unit)
    unit.learn_skill(@skill)
    true
  end

  def color_for(unit)
    GREEN
  end
end

class Vulnerary < Consumable
  def initialize
    super(3)
  end

  def name
    "Vulnerary (#{@charges})"
  end

  def consume(unit)
    unit.heal(10)
    true
  end

  def color_for(unit)
    GREEN
  end
end
