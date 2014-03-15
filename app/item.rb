class Item
  def self.create(name, *args)
    if Weapon.config.key?(name)
      Weapon.new(name)
    elsif Item.named?(name)
      Item.build(name)
    end
  end

  def self.named?(name)
    @registered ||= {}
    @registered.key?(name)
  end

  def self.register(hsh)
    @registered ||= {}
    hsh.each do |name, klass|
      @registered[name] = klass
    end
  end

  def self.build(name)
    @registered ||= {}
    @registered[name].new
  end

  def self.all_names
    Weapon.config.keys + @registered.keys
  end
end

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
