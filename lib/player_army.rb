class PlayerArmy
  def initialize(size)
    # build an army of size unit
    @army = 3.times.map do |x|
      klasses.shuffle.pop.new(PLAYER_TEAM, Names.generate, x+2, x==0)
    end
  end

  def next_level!
    purge_dead!
    recruit!
    heal_all_units!
    ready_all_units!
  end

  def klasses
    [ArmorKnight, Archer, Cavalier, Myrmidon, Mercenary, PegasusKnight, Fighter]
  end

  def recruit!
    @clevel ||= 0
    @army << klasses.shuffle.pop.new(PLAYER_TEAM, Names.generate, @clevel+=1)
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
