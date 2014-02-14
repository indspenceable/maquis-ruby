class WalkPathAction < Action
  def initialize(unit, path, level, &next_action)
    @unit, @path, @level, @next_action =
      unit, path, level, next_action
    @frame = 0
  end

  def frames_per_tile
    2
  end

  def draw(window)
    @frame += 1
    draw_map(window)
    if @frame < @path.length*frames_per_tile
      window.move_camera(*@path.at(@frame/frames_per_tile),@level.map_size_x, @level.map_size_y)
      draw_units(@level.units - [@unit], window)
      window.draw_char_at(*@path.at(@frame/frames_per_tile), @unit, true, :idle)
    else
      window.move_camera(*@path.last_point,@level.map_size_x, @level.map_size_y)
      @unit.at(*@path.last_point) { draw_units(@level.units, window) }
    end
  end

  def key(k)
    self
  end

  def auto
    if @frame > @path.length*frames_per_tile - 1
      @next_action.call
    else
      self
    end
  end
end
