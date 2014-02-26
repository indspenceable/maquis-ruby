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
end

class Antitoxin < Consumable
  def initialize
    super(1)
  end

  def name
    "Antitoxin"
  end

  def consume(unit)
    unit.debuff('poison')
  end
end
