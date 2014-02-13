class UnitSelect < MapAction
  attr_reader :level

  def current_unit
    @level.units.find{|c| c.x == @x && c.y == @y}
  end

  def initialize(x, y, level)
    @level = level
    @x, @y = x, y
  end
  def activate
    if current_unit && current_unit.action_available
      if current_unit.team == PLAYER_TEAM
        Move.new(@x, @y, @level)
      else
        HighlightEnemyMoves.new(current_unit, @level, self)
      end
    else
      TurnMenu.new(@level, self)
    end
  end
  def cancel
    self
    # Ahaha! Can't quit now, sucka.
  end
  def units_for_info_panel
    Array(@level.see?(@x,@y) && current_unit)
  end

  def key(k)
    if k == KEYS[:info] && !current_unit
      u = @level.units.find{|c| c.team == PLAYER_TEAM && c.action_available}
      @x, @y = u.x, u.y if u
      self
    else
      super(k)
    end
  end

  def cursor_xy
    [@x, @y]
  end

  def precalculate!
    @level.calculate_simple_fov(PLAYER_TEAM) if @level.fog_of_war
  end

  def draw(window)
    draw_map(window, cursor_xy)
    draw_all_units(window)
  end
end
