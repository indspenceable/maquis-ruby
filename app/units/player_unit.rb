class PlayerUnit < Unit
  attr_reader :exp

  def self.random_class
    config.keys.select do |k|
      config[k]['basic']
    end.shuffle.pop
  end

  LEVEL_UPS_FOR_LEVEL_ONE = 5

  BASE_STATS = {
    :max_hp => 15,
    :power => 1,
    :skill => 1,
    :armor => 0,
    :speed => 0,
    :resistance => 0,
  }

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
      raise "#{stat} growth undefined for #{@klass}!" unless class_growths[stat] || stat==:constitution
    end

    @growths = {}

    average = false
    if average
      class_growths.each do |k, val|
        (val/2)+20
        @growths[k] = val
      end
    else
      class_growths.each do |k, val|
        min,max = 20, val+20
        @growths[k] = rand((max-min)/5)*5 + min
      end
    end

    # lords have universally improved growths. Look out, myrmidon lord skill stat...
    if is_lord
      @growths.keys.each do |k|
        @growths[k] += (rand(3)+1)*5
      end
    end

    @hp = max_hp
    @inventory = [
      IronSword.new,
      IronLance.new,
      IronAxe.new,
      IronBow.new,
      Lightning.new,
      Flux.new,
      Fire.new,].shuffle
    @inventory = available_weapons

    @exp_level = 0
    if average
      jump_to_exp_level(exp_level)
    else
      (exp_level + LEVEL_UPS_FOR_LEVEL_ONE - 1).times { exp_level_up! }
    end
    @exp_level = exp_level

    @is_lord = is_lord
    @exp = 0
  end

  def self.config
    @config ||= YAML.load(File.read('./units.yml'))
  end

  def class_growths
    config[@klass]['growths']
  end

  def starting_stats
    BASE_STATS.merge({
      :constitution => config[@klass]['con'] + rand(5)-2
    })
  end

  def gain_experience n
    @exp += n
    if @exp >= 100
      @exp -= 100
      return exp_level_up!
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
