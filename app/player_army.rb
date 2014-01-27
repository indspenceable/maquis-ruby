class PlayerArmy
  def initialize(size)
    # build an army of size unit
    @army = size.times.map do |x|
      klasses.shuffle.pop.new(PLAYER_TEAM, Names.generate, 1, x==0)
    end
  end

  def next_level!
    purge_dead!
    # recruit!
    heal_all_units!
    ready_all_units!
  end

  def klasses
    [ArmorKnight, Archer, Cavalier, Myrmidon, Mercenary, PegasusKnight, Fighter]
  end

  def recruit! r
    # @clevel ||= 0
    # @army << klasses.shuffle.pop.new(PLAYER_TEAM, Names.generate, @clevel+=1)
    @army << r
  end

  def possible_recruits(diff)
    rtn = []
    klasses.shuffle.first(3).each_with_index do |k,x|
      rtn << k.new(PLAYER_TEAM, Names.generate, diff+x-1)
    end
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
