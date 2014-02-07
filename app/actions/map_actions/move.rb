require './app/path'

class Move < MapAction
  attr_reader :level

  def initialize(x, y, level)
    @x, @y = x, y
    @level = level
    @unit = current_highlighted_unit
    @path = Path.new(x,y,level)
  end

  def name
    'move'
  end

  def current_highlighted_unit
    @level.units.find{|c| c.x == @x && c.y == @y}
  end

  def units_for_info_panel
    [@unit, @level.see?(@x,@y) && @level.unit_at(@x,@y)].compact.uniq
  end

  def ignore_range
    @unit.weapon.range.to_a.first if @unit.weapon
  end

  def adjacent_to_last_point?(x,y)
    xx,yy=@path.last_point
    ((xx-x).abs + (yy-y).abs) == 1
  end

  def can_add_to_path?(x,y)
    @path.dup.add(x,y).cost(@unit) <= @unit.movement &&
    adjacent_to_last_point?(x,y) &&
    ( @level.unit_at(x,y).nil? ||
      @level.unit_at(x,y).team == @unit.team ||
      !@level.see?(x,y) )
  end

  def update(x,y)
    if @path.include?(x,y)
      # if this space is already on the path
      @path.trim_to(x,y)
    else
      if can_add_to_path?(x,y)
        @path.add(x,y)
      else
        @path = Path.find(@unit, x, y, @level, @unit.movement, :block_seen) || @path
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
    UnitSelect.new(@x, @y, @level)
  end

  def activate
    if [@x,@y] == @path.last_point &&
      @level.units.all? do |u|
        (u.x != @x ||
         u.y != @y ||
         u == @unit ||
         !@level.see?(@x, @y))
      end
      # We've got a clear path to this location.
      # move the unit there

      ee = early_end
      if ee
        @unit.x, @unit.y = ee.last_point
        @unit.action_available = false
        return UnitSelect.new(*ee.last_point, @level)
      else
        return ConfirmMove.new(@unit, @path, @level, self)
      end
    end
    self
  end

  def early_end
    last_good_point = nil
    @path.each do |p|
      u = @level.unit_at(*p)
      if u && u.team != @unit.team
        success_path = @path.dup
        success_path.trim_to(*last_good_point)
        return success_path
      end
      last_good_point = p
    end
    nil
  end

  def cursor_xy
    [@x, @y]
  end

  def precalculate!
    squares_to_color_for_highlighting(@unit)
    @level.calculate_simple_fov(PLAYER_TEAM) if @level.fog_of_war
  end

  def draw(window)
    draw_map(window, cursor_xy)
    window.draw_path(@path)
    window.highlight(squares_to_color_for_highlighting(@unit))
  end
end
