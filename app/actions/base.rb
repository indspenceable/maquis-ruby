class Action
  def initialize
    raise "trying to initialize abstract class Action!"
  end

  def draw(window)
    raise "#{self.class.name} doesn't implement #draw!"
  end

  # Releys on @level
  def draw_map(window, cursor_location = nil)
    # this should actually just place all of the terrain tiles
    MAP_SIZE_X.times do |x|
      MAP_SIZE_Y.times do |y|
        add_map_location(window,x,y)
      end
    end
    # then, look through all units
    # then place the cursor
    window.draw_cursor(*cursor_location) if cursor_location
  end

  def squares_to_color_for_highlighting(c)
    return @squares_to_color_for_highlighting ||= begin
      movements = Path.discover_paths(c, @level, c.movement, :block_seen).map(&:last_point)
      movements_with_no_one_there = movements.reject do |m|
        u = @level.unit_at(*m)
        (u && u != c && @level.see?(*m))
      end
      attack = []
      MAP_SIZE_X.times do |x|
        MAP_SIZE_Y.times do |y|
          attack << [x,y] if movements_with_no_one_there.any? do |_x,_y|
            c.weapons_that_hit_at(Path.dist(x, y, _x, _y)).any?
          end
        end
      end
      attack -= movements_with_no_one_there
      attack -= @level.units.select{|u| u.team == c.team }.map{|u| [u.x, u.y]}
      rtn = {}
      movements.each do |x,y|
        rtn[[x,y]] = :blue
      end
      attack.each do |x,y|
        rtn[[x,y]] = :red
      end
      rtn
    end
  end

  # this method figures out the right glyph to draw, and draws it
  def add_map_location(window, x, y)
    window.draw_terrain(x, y, @level.map(x,y), @level.see?(x,y))
  end

  def draw_all_units(window)
    draw_units(@level.units, window)
  end

  def draw_units(units, window)
    units.each do |u|
      window.draw_char_at(u.x, u.y, u, @unit == u, :idle_animation) if u.team == PLAYER_TEAM || @level.see?(u.x,u.y)
    end
  end

  def draw_character_info_panel(window)
    a,b = units_for_info_panel
    window.draw_character_info(a,b, ignore_range)
  end

  def ignore_range
    false
  end
end
