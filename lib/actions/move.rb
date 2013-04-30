require './lib/path'

class Move < MapAction
  def initialize(x, y, level)
    @x, @y = x, y
    @level = level
    @unit = current_highlighted_unit
    @path = Path.new(x,y,level)
    @valid = true
  end
  def name
    'move'
  end

  def current_highlighted_unit
    @level.units.find{|c| c.x == @x && c.y == @y}
  end

  def units_for_info_panel
    [@unit, current_highlighted_unit].uniq.compact
  end

  def adjacent_to_last_point?(x,y)
    xx,yy=@path.last_point
    ((xx-x).abs + (yy-y).abs) == 1
  end

  def update(x,y)
    if @path.include?(x,y)
      # if this space is already on the path
      @path.trim_to(x,y)
      @valid = true
    elsif @level.map[x][y] == ' '
      if @path.length <= @unit.movement &&
        adjacent_to_last_point?(x,y)
          @path.add(x,y)
      else
        @path = Path.find(@unit, x, y, @level, @unit.movement) || @path
      end
    end

    [x,y]
  end

  def key(c)
    rtn = super
    update(@x,@y)
    rtn
  end

  def cancel
    MapSelect.new(@x, @y, @level)
  end

  def draw(screen)
    @path.each_but_last do |x,y|
      screen.map.set_xy(x,y)
      screen.map.draw_str('*', GREEN)
    end
  end

  def activate
    if [@x,@y] == @path.last_point &&
     @level.units.all? {|u| (u.x != @x || u.y != @y) || (u == @unit)}
      # We've got a clear path to this location.
      # move the unit there
      return ConfirmMove.new(@unit, @path, @level, self)
    end
    self
  end

  def set_cursor(screen)
    screen.map.set_xy(@x, @y)
  end

  def unit_for_map_highlighting
    @unit
  end
end
