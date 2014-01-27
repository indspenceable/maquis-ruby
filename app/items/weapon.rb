class Weapon
  ATTRS = [:name, :weapon_type, :range, :power, :to_hit, :to_crit, :weight, :targets]
  attr_reader *ATTRS

  def initialize *attrs
    ATTRS.count.times do |i|
      instance_variable_set("@#{ATTRS[i]}", attrs[i])
    end
  end

  def in_range?(x)
    range.include?(x)
  end

  def self.create(*args)
    @all||=[]
    c = Class.new(self) do
      define_method :initialize do
        super(*args)
      end
    end
    @all << c
    c
  end

  # override if different from their triangle weapon type
  # examples: axekiller is wieldable by lances, but in other cases is a sword.
  def wield_type
    weapon_type
  end

  # equip!
  def trigger!(unit)
    if unit.can_wield?(self)
      unit.equip!(self)
    end
    false
  end

  def color_for(unit)
    if unit.can_wield?(self)
      GREEN
    else
      YELLOW
    end
  end

  def used_up?
    #TODO weapon durabilities
    false
  end

  def targets
    @targets || []
  end
end
