class Enemy < Unit
  attr_reader :ai, :exp_level

  def self.class_below_difficulty(ov)
    rtn = []
    config.each do |k, v|
      rtn << k if v['value'] <= ov
    end
    return rtn.shuffle.pop
  end

  def lord?
    false
  end

  def name
    if boss?
      "Count #{@name.capitalize}"
    else
      @name.capitalize
    end
  end

  def boss?
    @boss
  end

  def self.config
    @config ||= YAML.load(File.read('./config/enemies.yml'))
  end

  def self.random_class
    config.keys.shuffle.pop
  end

  def select_valid_ai!
    # ai_name = config[@klass]['ais'].shuffle.pop
    @ai = if rand(2) == 0
      CautiousAI.new
    else
      ZerkAI.new
    end
  end

  def stat_for(stat)
    config[@klass]['stats'][stat.to_s]
  end

  def exp_string
    ''
  end

  def strength_string(stat)
    ""
  end

  def initialize(klass, name, exp_level, boss)
    @klass = klass
    @name = name
    @boss = boss
    @team = COMPUTER_TEAM
    @x, @y = 0, 0
    @buffs = []

    raise "no value for #{@klass}!" unless config[@klass]['value']
    number_of_level_ups = exp_level - config[@klass]['value']
    raise "exp_level (#{number_of_level_ups}) < 0!" if number_of_level_ups < 0

    #ensure everyone is exp_level 1 at least.
    @action_available = true

    (STATS+[:constitution]).each do |stat|
      raise "No stat for #{stat} for enemy #{klass}" unless stat_for(stat)
      target_value = stat_for(stat) + (number_of_level_ups * 0.35).to_i
      self.instance_variable_set(:"@#{stat}", target_value )
    end
    @hp = max_hp
    @inventory = config[@klass]['weapons'].map do |w|
      Weapon.new(w)
    end
    @exp_level = exp_level
  end

  def can_wield?(weapon)
    true
  end
end
