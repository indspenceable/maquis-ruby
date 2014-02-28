class PlayerUnit < Unit
  attr_reader :exp, :pending_exp

  def self.random_class_weighted
    classes = []
    config.each do |klass, val|
      val['weight'].times{ classes << klass } if val['basic']
    end
    return classes.shuffle.pop
  end

  def self.random_lord_class
    config.keys.select do |k|
      config[k]['basic'] && config[k]['lord']
    end.shuffle.pop
  end

  def self.random_class
    config.keys.select do |k|
      config[k]['basic']
    end.shuffle.pop
  end

  def name
    if lord?
      "Lord #{@name.capitalize}"
    else
      @name.capitalize
    end
  end

  LEVEL_UPS_FOR_LEVEL_ONE = 5

  AVERAGE_NUMBER_OF_POINTS = STATS.length-1
  # GROWTH_RANGES = {
  #   :max_hp => [60, 90],
  #   :power => [15, 60],
  #   :skill => [20, 60],
  #   :armor => [15, 55],
  #   :speed => [20, 60],
  #   :resistance => ,
  # }
  GROWTH_LOW = 15
  GROWTH_HIGH = 60
  NUMBER_OF_RANGES = 3 # bad, med, good.
  SINGLE_RANGE = (GROWTH_HIGH-GROWTH_LOW)/NUMBER_OF_RANGES
  HEALTH_BONUS_GROWTH = 30
  # < 30 LOW
  # < 45 MED
  # < 60 HIGH
  # >= 60

  def initialize klass, name, exp_level = 1, is_lord=false
    @klass = klass
    @name = name
    @team = PLAYER_TEAM
    @x, @y = 0, 0
    @buffs = []

    #ensure everyone is exp_level 1 at least.
    exp_level = 1 if exp_level < 1

    @action_available = true
    STATS.each do |stat|
      self.instance_variable_set(:"@#{stat}", starting_stats[stat])
      raise "#{stat} starting value undefined for #{@klass}!" unless starting_stats[stat]
      # raise "#{stat} growth undefined for #{@klass}!" unless class_growths[stat] || stat==:constitution
    end
    @constitution = config[@klass]['con'] + rand(5)-2

    @growths = {}

    # create this characters skill array
    general_aptitudes = Hash[STATS.map{ |s| [s, 0] }]
    points_for_me = AVERAGE_NUMBER_OF_POINTS + rand(3) - 1

    while general_aptitudes.values.reduce(&:+) < points_for_me
      current_stat = STATS.shuffle.pop
      if general_aptitudes[current_stat] < 2
        general_aptitudes[current_stat] += 1
      end
    end

    config[@klass]['growths'].each do |stat, val|
      if val >= 1
      else
      end
      general_aptitudes[stat] += val
    end

    general_aptitudes.each do |stat, val|
      val = 0 if val < 0
      val = 3 if val > 3
      @growths[stat] = rand(SINGLE_RANGE/5)*5 + GROWTH_LOW + SINGLE_RANGE*val
    end
    @growths[:max_hp] += HEALTH_BONUS_GROWTH


    # class_growths.each do |k, val|
    #   min,max = 20, val+20
    #   @growths[k] = rand([(max-min)/5, 1].max)*5 + min
    # end

    # lords have universally improved growths. Look out, myrmidon lord skill stat...
    if is_lord
      @growths.keys.each do |k|
        @growths[k] += (rand(3)+1)*5
      end
    end

    @hp = max_hp
    # @inventory = [Weapon.new('iron_sword')].shuffle

    @inventory = []
    if config[@klass]['weapons'].any?
      @inventory << Weapon.new(config[@klass]['weapons'].shuffle.pop)
    end
    @inventory << Vulnerary.new

    @exp_level = 0
    (exp_level + LEVEL_UPS_FOR_LEVEL_ONE - 1).times { exp_level_up! }
    @exp_level = exp_level

    @is_lord = is_lord
    @exp = 0
    @pending_exp = 0
  end

  def strength_string(stat)
    pct = @growths[stat]
    pct -= HEALTH_BONUS_GROWTH if stat == :max_hp
    case
    when pct < GROWTH_LOW
      "VERY LOW"
    when pct < GROWTH_LOW+SINGLE_RANGE
      "LOW"
    when pct < GROWTH_LOW+SINGLE_RANGE*2
      "MEDIUM"
    when pct < GROWTH_LOW+SINGLE_RANGE*3
      "HIGH"
    else
      "!!!"
    end
  end

  def self.config
    @config ||= YAML.load(File.read('./units.yml'))
  end

  def class_growths
    config[@klass]['growths']
  end

  def starting_stats
    # 20 max hp to start, con determined by class,
    # and random base stats beyond that.
    Hash[
      STATS.map do |k|
        [k, rand(5)]
      end
    ].merge({
      :max_hp => 15 + 5*rand(3),
    })
  end

  def gain_experience n
    @pending_exp += n
  end

  def apply_exp_gain
    @exp += @pending_exp
    @pending_exp = 0
    if @exp >= 100
      @exp -= 100
      return puts exp_level_up!.inspect
    end
  end

  def exp_string
    "% 3d/100 xp" % exp
  end

  def exp_level_up!
    @exp_level += 1
    stats_grown = []
    @growths.each do |stat, growth|
      if rand(100) < growth
        stats_grown << stat
        current_val = instance_variable_get(:"@#{stat}")
        instance_variable_set(:"@#{stat}", current_val + 1)
        # increase current hp when max_hp rises.
        @hp += 1 if stat == :max_hp
      end
    end
    stats_grown
  end

  def lord?
    @is_lord
  end

  def summary
    "#{name} (#{pretty_name}: #{exp_level})"
  end
end
