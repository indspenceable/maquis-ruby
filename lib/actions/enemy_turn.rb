class EnemyTurn
  def initialize level
    @level = level
  end
  def execute
    @level.units.each{|u| u.action_available = true }
    first_unit = @level.units.find{|u| u.team == PLAYER_TEAM}
    MapSelect.new(first_unit.x, first_unit.y, @level)
  end
  def draw(screen)
  end
  def key(c)
  end
end
