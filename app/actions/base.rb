class Action

  def initialize
    raise "trying to initialize abstract class Action!"
  end

  def display(screen)
    display_map(screen)
    display_character_info_panel(screen)
    display_messages(screen)
    # draw_special(screen)
  end

  def draw_special(screen)
  end

  # Releys on @level, #unit_for_map_highlihgting
  def display_map(screen)
    #at this point, discover what paths we can go to.
    highlight_spaces = {}
    c = unit_for_map_highlighting
    if c
      highlight_spaces = squares_to_color_for_highlighting(c)
    end
    # this should actually just place all of the terrain tiles
    MAP_SIZE_X.times do |x|
      MAP_SIZE_Y.times do |y|
        add_map_location(screen,x,y, highlight_spaces)
      end
    end
    # then, look through all units
    # then place the cursor
    screen.draw_cursor(*cursor_xy)
  end

  def precalculate!
    @level.calculate_simple_fov(PLAYER_TEAM) if @level && @level.fog_of_war
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
        rtn[[x,y]] = BLUE
      end
      attack.each do |x,y|
        rtn[[x,y]] = RED
      end
      rtn
    end
  end

  # this method figures out the right glyph to draw, and draws it
  def add_map_location(screen, x, y, highlight_squares)
    if @level.see?(x,y) && @level.unit_at(x,y)
      screen.draw_char_at(x, y, @level.unit_at(x,y), highlight_squares)
    else
      screen.draw_terrain(x, y, @level.map(x,y), highlight_squares, @level.see?(x,y))
    end
  end

  def display_character_info_panel(screen)
    a,b = units_for_info_panel
    screen.display_character_info(a,b, ignore_range)
  end

 # uses @messages, releys on nothing.
  def display_messages(screen)
    screen.draw_messages(@messages) if @messages
  end

  def ignore_range
    false
  end
end
