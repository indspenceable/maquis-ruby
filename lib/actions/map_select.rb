class MapAction
  def key(c)
    case c
    when 'k'
      @y -= 1
    when 'h'
      @x -= 1
    when 'j'
      @y += 1
    when 'l'
      @x += 1
    when 'a'
      if respond_to?(:activate)
        rtn = activate
        return rtn if rtn
      end
    end
    self
  end
end

class MapSelect < MapAction
  def current_unit
    @level.units.find{|c| c.x == @x && c.y == @y}
  end
  def initialize(x, y, level)
    @level = level
    @x, @y = x, y
  end
  def activate
    if current_unit && current_unit.action_available &&
      current_unit.team == PLAYER_TEAM
      Move.new(@x, @y, @level)
    else
      TurnMenu.new(@level, self)
    end
  end
  def cancel
    raise "herp derp derp"
  end
  def units_for_info_panel
    Array(current_unit)
  end
  def unit_for_map_highlighting
    nil
  end
  def draw(screen)
  end
  def set_cursor(screen)
    screen.map.set_xy(@x,@y)
  end
end
