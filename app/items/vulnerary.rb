class Vulnerary < Consumable
  def initialize
    super(3)
  end

  def name
    "Vulnerary (#{@charges})"
  end

  def consume(unit)
    unit.heal(10)
    unit.animation_queue << "vulnerary"
    true
  end

  def price
    300
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
    unit.animation_queue << "heal status"
  end

  def price
    150
  end
end

Item.register('vulnerary' => Vulnerary)
Item.register('antitoxin' => Antitoxin)
