class MapAction < Action
  def initialize
    raise "trying to initialize abstract class MapAction!"
  end
  def key(c)
    case c
    when KEYS[:up]
      @y -= 1
    when KEYS[:left]
      @x -= 1
    when KEYS[:down]
      @y += 1
    when KEYS[:right]
      @x += 1
    when KEYS[:info]
      u = @level.unit_at(@x,@y)
      if u
        team = @level.units.select{|u2| u.team == u2.team}
        return UnitInfo.new(u, team, self)
      end
    when KEYS[:accept]
      if respond_to?(:activate)
        rtn = activate
        return rtn if rtn
      end
    end
    @x = [[@x, MAP_SIZE_X-1].min, 0].max
    @y = [[@y, MAP_SIZE_Y-1].min, 0].max
    self
  end
end
