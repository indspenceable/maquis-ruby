class UnitInfo < Action
  def initialize(unit, team, prev_action)
    @index = team.index(unit)
    @team = team
    @prev_action = prev_action
  end

  def key(c)
    if c == KEYS[:down]
      @index += 1
    elsif c == KEYS[:up]
      @index -= 1
    end

    @index = @index % @team.count
    self
  end

  def cancel
    @prev_action
  end

  def draw(window)
    window.extended_character_info(@team[@index])
  end
end
