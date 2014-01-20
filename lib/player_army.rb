class PlayerArmy
  def initialize(size)
    # build an army of size unit
    @army = 3.times.map do |x|
      klasses.shuffle.pop.new(PLAYER_TEAM, Names.generate, x+2, x==0)
    end
  end

  def klasses
    [ArmorKnight, Archer, Cavalier, Myrmidon, Mercenary, PegasusKnight, Fighter]
  end

  def recruit!(level)
    @army << klasses.shuffle.pop.new(PLAYER_TEAM, Names.generate, level)
  end

  def units
    @army
  end
  def purge_dead!
    @army.select!(&:alive?)
  end
end
