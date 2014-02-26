class Weapon
  ATTRS = [:name, :type, :range, :power, :to_hit, :to_crit, :weight, :targets] +
    [:on_hit]

  DEFAULTS = {
    :targets => [],
    :on_hit => [],
  }

  attr_reader *ATTRS
  attr_reader :config

  def self.config
    @config ||= YAML.load(File.read('./weapons.yml'))
  end

  def initialize identifier
    raise "No weapon named: #{identifier}" unless Weapon.config[identifier]
    @config = Weapon.config[identifier]
    @identifier=identifier
    ATTRS.each do |stat|
      val = config[stat.to_s] || DEFAULTS[stat]
      raise "Weapon #{@identifier} doens't have stat #{stat}!" unless val
      instance_variable_set("@#{stat}", val)
    end
    @range = (@range..@range) if @range.is_a?(Numeric)
  end

  def in_range?(x)
    range.include?(x)
  end

  def self.exists?(name)
    config.key?(name)
  end

  # override if different from their triangle weapon type
  # examples: axekiller is wieldable by lances, but in other cases is a sword.
  def wield_type
    type
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

  def magic?
    [:anima, :light, :dark].include?(type)
  end

  def hit(target)
    on_hit.each do |m|
      __send__("on_hit_#{m}", target)
    end
  end

  def on_hit_poison(target)
    target.buff!('poison', 3, 5)
  end
end

