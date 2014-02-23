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
    window.draw_map(@level)
    if cursor_location
      window.move_camera(*cursor_location,@level.map_size_x, @level.map_size_y)
      window.draw_cursor(*cursor_location)
    end
  end

  def squares_to_color_for_highlighting(c)
    return @squares_to_color_for_highlighting ||= begin
      movements = Path.discover_paths(c, @level, c.movement, :block_seen).map(&:last_point)
      movements_with_no_one_there = movements.reject do |m|
        u = @level.unit_at(*m)
        (u && u != c && @level.see?(*m))
      end
      max_x = movements.map(&:first).max+2
      max_y = movements.map(&:last).max+2
      min_x = movements.map(&:first).min-2
      min_y = movements.map(&:last).min-2

      attack = []
      (min_x..max_x).each do |x|
        (min_y..max_y).each do |y|
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

  def unit_brief(window, unit)
    window.draw_menu([
      unit.name,
      unit.pretty_name,
      unit.health_str
    ], nil)
  end

  def add_map_location(window, x, y)
    window.draw_terrain(x, y, @level.map(x,y), @level.see?(x,y))
  end

  def draw_all_units(window)
    draw_units(@level.units, window)
  end

  def draw_units(units, window)
    units.each do |u|
      window.draw_char_at(u.x, u.y, u, @unit == u, :idle) if u.team == PLAYER_TEAM || @level.see?(u.x,u.y)
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
