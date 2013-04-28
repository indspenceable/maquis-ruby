class Weapon
  attrs :name, :power, :to_hit, :to_crit, :weight
  def self.stats(*args)
    define_method :initialize do
      super(*args)
    end
  end
end

class IronSword < Weapon
  stats 'Iron Sword', 5, 90, 0, 5
end
class IronLance < Weapon
  stats 'Iron Lance', 7, 80, 0, 8
end
class IronAxe < Weapon
  stats 'Iron Axe', 8, 75, 0, 10
end
