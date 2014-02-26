class Reward
end

class GainAUnit < Reward
  def initialize(difficulty)
    @level = difficulty
  end
  def apply(player_army)
    player_army.units << PlayerUnit.new(PlayerUnit.random_class, Names.generate, @level)
  end
end
