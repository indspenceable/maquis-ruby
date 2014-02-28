class GainAUnit
  def initialize(difficulty)
    @level = difficulty
  end
  def apply(player_army)
    player_army.units << PlayerUnit.new(PlayerUnit.random_class, Names.generate, @level)
  end
  def description
    "a new unit"
  end
end

class GainMoney
  def initialize(difficulty)
    @level = difficulty
  end
  def apply(player_army)
    player_army.money += @level * 300 + rand(300)
  end
  def description
    "some cash"
  end
end

# Weapon.advanced_names.shuffle.first([rand(5)-3,0].max)
