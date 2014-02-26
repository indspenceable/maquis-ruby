class Terrain
  def armor_bonus
    0
  end

  def evade_bonus
    0
  end

  def available_to_place_units?
    false
  end

  def tile
    identifier
  end
end

class Plains < Terrain
  def identifier
    :plains
  end

  def available_to_place_units?
    true
  end
end

class Mountain < Terrain
  def identifier
    :mountain
  end
end

class Forest < Terrain
  def identifier
    :forest
  end

  def available_to_place_units?
    true
  end
end

class Wall < Terrain
  def identifier
    :wall
  end
end

class Fort < Terrain
  def identifier
    :fort
  end

  def available_to_place_units?
    true
  end
end
