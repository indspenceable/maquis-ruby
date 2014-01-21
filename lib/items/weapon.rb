class Weapon
  ATTRS = [:name, :weapon_type, :range, :power, :to_hit, :to_crit, :weight]
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

  # override if different from their triangle weapon type
  # examples: axekiller is wieldable by lances, but in other cases is a sword.
  def wield_type
    weapon_type
  end
end
