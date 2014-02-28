class ChapterGoal
  def initialize(level)
    @level = level
  end

  def event!(event)
  end
end

class SeizeThrone < ChapterGoal
  def primary?
    true
  end

  def event!(event)
    @completed = true if event == :seize_throne
    super(event)
  end

  def met?
    @completed
  end

  def description
    "Seize the Throne"
  end
end

class KillAllBaddies < ChapterGoal
  def primary?
    true
  end

  def met?
    @level.units.select{|x| x.team == COMPUTER_TEAM }.none?
  end

  def description
    "Kill all enemies"
  end
end

class KillAllBosses < ChapterGoal
  def primary?
    true
  end

  def met?
    @level.units.select{|x| x.team == COMPUTER_TEAM && x.boss? }.none?
  end

  def description
    "Kill the enemy leader"
  end
end

class WinInXTurns < ChapterGoal
  def primary?
    false
  end

  def initialize(turns, level)
    @turns = turns
    super(level)
  end

  def event!(event)
    if @level.turn_count < @turns
      @completed = false
    end

    super(event)
  end

  def description
    "Win in #{@turns} turns"
  end

  def met?
    @completed
  end
end
