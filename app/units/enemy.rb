class Enemy < Unit
  attr_reader :ai

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
    @config ||= YAML.load(File.read('./enemies.yml'))
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
    config[@klass]['stats'][stat]
  end

  def exp_string
    ''
  end

  def exp_level
    config[@klass]['value']
  end

  def strength_string(stat)
    ""
  end

  def initialize(klass, name, boss=false)
    @klass = klass
    @name = name
    @boss = boss
    @team = COMPUTER_TEAM
    @x, @y = 0, 0
    @buffs = []

    #ensure everyone is exp_level 1 at least.
    @action_available = true

    (STATS+[:constitution]).each do |stat|
      self.instance_variable_set(:"@#{stat}", stat_for(stat) )
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
