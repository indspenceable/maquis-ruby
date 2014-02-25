class PlayerArmy
  attr_reader :inventory
  def name
    "Stash"
  end

  def initialize(size)
    # build an army of size units, plus the lord.

    # lord = lord_klasses.shuffle.pop.new(PLAYER_TEAM, Names.generate, 1, true)
    lord = PlayerUnit.new(PlayerUnit.random_class, Names.generate, 1, true)
    @army = [ lord ]
    @army += size.times.map do |x|
      PlayerUnit.new(PlayerUnit.random_class, Names.generate, 1)
    end
    @army.each do |u|
      u.inventory << Vulnerary.new
    end
    @inventory = []
    # @inventory = Array.new(10) { SkillToken.new(all_skills.shuffle.pop.new) }
  end

  def next_level!
    purge_dead!
    heal_all_units!
    ready_all_units!
    @army.each{|u| u.current_level = nil}
    @army.each{|u| u.clear_buffs! }
  end

  def possible_recruits(diff)
    rtn = []
    klasses.shuffle.first(3).each_with_index do |k,x|
      rtn << k.new(PLAYER_TEAM, Names.generate, diff+x-1)
    end
    return []
    rtn
  end

  def units
    @army
  end

  def purge_dead!
    @army.select!(&:alive?)
  end

  def heal_all_units!
    @army.each(&:heal)
  end

  def ready_all_units!
    @army.each{|u| u.action_available = true}
  end
end
