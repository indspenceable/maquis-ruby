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
    when KEYS[:accept]
      if respond_to?(:activate)
        rtn = activate
        return rtn if rtn
      end
    end
    self
  end
end
