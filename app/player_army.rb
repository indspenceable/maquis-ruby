class PlayerArmy
  def initialize(size)
    # build an army of size units, plus the lord.

    lord = lord_klasses.pop.new(PLAYER_TEAM, Names.generate, 1, true)
    @army = [
      lord
    ]
    @army += size.times.map do |x|
      klasses.pop.new(PLAYER_TEAM, Names.generate, 1)
    end
    @army.each do |u|
      u.inventory << Vulnerary.new
    end
  end

  def next_level!
    purge_dead!
    # recruit!
    heal_all_units!
    ready_all_units!
  end

  def lord_klasses
    [ArmorKnight, Myrmidon, Mercenary, Fighter]
  end

  def klasses
    @klass_list ||= [
      [PegasusKnight] * 3,
      [ArmorKnight] * 2,
      [Cavalier] * 5,
      [Myrmidon] * 2,
      [Archer] * 2,
      [Fighter] * 2,
      [Mercenary] * 2,
      [Cleric] * 1,
      [Mage] * 1,
      [Monk] * 1,
      [Nomad] * 1,
      [Shaman] * 1,
      [WyvernRider] * 1,
    ].flatten.shuffle
  end

  def recruit! r
    # @clevel ||= 0
    # @army << klasses.shuffle.pop.new(PLAYER_TEAM, Names.generate, @clevel+=1)
    @army << r
  end

  def possible_recruits(diff)
    rtn = []
    # klasses.shuffle.first(3).each_with_index do |k,x|
    #   rtn << k.new(PLAYER_TEAM, Names.generate, diff+x-1)
    # end
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
