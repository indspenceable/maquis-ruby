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

  def actions
    {}
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

class Shop < Terrain
  attr_reader :items

  def initialize
    @items = [
      Weapon.new('iron_sword'),
      Weapon.new('iron_axe'),
    ]
  end

  def identifier
    :shop
  end

  def available_to_place_units?
    false
  end

  def actions
    if @items.any?
      {
        :shop => ShopAction
      }
    else
      {}
    end
  end
end
