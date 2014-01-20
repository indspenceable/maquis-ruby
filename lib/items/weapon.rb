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

  def self.create(*args)
    @all||=[]
    c = Class.new(self) do
      stats(*args)
    end
    @all << c
    c
  end
  def self.all
    @all || []
  end

  # override if different from their triangle weapon type
  # examples: axekiller is wieldable by lances, but in other cases is a sword.
  def wield_type
    weapon_type
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

SlimSword = Sword.create 'Slim Sword', 3, 100, 5, 2
IronSword = Sword.create 'Iron Sword', 5, 90, 0, 5
SteelSword = Sword.create 'Steel Sword', 8, 75, 0, 10
KillingEdge = Sword.create 'Killing Edge', 9, 75, 30, 7
SilverSword = Sword.create 'Silver Sword', 13, 80, 0, 8

SlimLance = Lance.create 'Slim Lance', 4, 85, 5, 4
IronLance = Lance.create 'Iron Lance', 7, 80, 0, 8
Javalin = Lance.create 'Javalin', 6, 65, 0, 11
Javalin.__send__(:define_method, :range){(1..2)}
SteelLance = Lance.create 'Steel Lance', 10, 70, 0, 13
SilverLance = Lance.create 'Silver Lance', 14, 75, 0, 10

HandAxe = Axe.create 'Hand Axe', 7, 60, 0, 12
HandAxe.__send__(:define_method, :range){(1..2)}
IronAxe = Axe.create 'Iron Axe', 8, 75, 0, 10
SteelAxe = Axe.create 'Steel Axe', 11, 65, 0, 15
# Halberd = Axe.create...
# Hammer = Axe.create...
# TODO specify extra damage towards a unit type
# This will be useful for bows / pegasus knight.
SilverAxe = Axe.create 'Silver Axe', 15, 70, 0, 12

IronBow = Bow.create 'Iron Bow', 6, 85, 0, 5
