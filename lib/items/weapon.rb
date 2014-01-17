class Weapon
  ATTRS = [:name, :power, :to_hit, :to_crit, :weight]
  attr_reader *ATTRS
  def initialize *attrs
    ATTRS.count.times do |i|
      instance_variable_set("@#{ATTRS[i]}", attrs[i])
    end
  end

  def self.stats(*args)
    define_method :initialize do
      super(*args)
    end
  end

  def in_range?(x)
    range.include?(x)
  end
end

class Sword < Weapon
  def range
    (1..1)
  end
  def weapon_type
    :swords
  end
end
class Lance < Weapon
  def range
    (1..1)
  end
  def weapon_type
    :lances
  end
end
class Axe < Weapon
  def range
    (1..1)
  end
  def weapon_type
    :axes
  end
end
class Bow < Weapon
  def range
    (2..2)
  end
  def weapon_type
    :bows
  end
end

class IronSword < Sword
  stats 'Iron Sword', 5, 90, 0, 5
end
class IronLance < Lance
  stats 'Iron Lance', 7, 80, 0, 8
end
class IronAxe < Axe
  stats 'Iron Axe', 8, 75, 0, 10
end
class IronBow < Bow
  stats 'Iron Bow', 6, 85, 0, 5
end
