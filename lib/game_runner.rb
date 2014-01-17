require './lib/permissive_fov'
require './lib/display/region'
require './lib/display/screen'
require './lib/actions/menu'
require './lib/actions/map_select'
require './lib/actions/move'
require './lib/actions/confirm_move'
require './lib/actions/enemy_turn'
require './lib/level'
require './lib/names'
require './lib/items/weapon'
require './lib/units/base'

#constants go here too, cause yolo

MAP_SIZE_X = 40
MAP_SIZE_Y = 20

BLUE = 1
RED = 2
GREEN = 3

PLAYER_TEAM = 0
COMPUTER_TEAM = 1


module GameRunner
  def setup
    klasses = [ArmorKnight, Archer, Cavalier, Myrmidon, Mercenary, PegasusKnight, Fighter].shuffle
    l = 3
    pl = 3.times.map do |x|
      kl = klasses.shuffle.pop
      u = kl.new(PLAYER_TEAM, Names.generate, 0, 0, l+2, x==0)
      l -= 1 if l > 1
      u
    end
    level = Level.generate(pl, 1)
    @x, @y = 1, 1
    @current_action = MapSelect.new(3, 3, level)
  end

  def display(screen)
    display_map(screen)
    display_character_info(screen)
    display_messages(screen)

    draw_current_action(screen)
    # screen.map.set_xy(@x,@y)
    finish_display
  end

    def display_map(screen)
    #at this point, discover what paths we can go to.
    highlight_spaces = []
    c = @current_action.unit_for_map_highlighting
    if c
      highlight_spaces += Path.discover_paths(c, @current_action.level, c.movement).map(&:last_point)
    end
    # lit_spaces = @current_action.level.calculate_fov(@current_action.level.units.select{|u| u.team == PLAYER_TEAM })
    lit_spaces = nil
    MAP_SIZE_X.times do |x|
      MAP_SIZE_Y.times do |y|
        add_glyph(screen,x,y, highlight_spaces, lit_spaces)
      end
    end
  end


  def execute
    @current_action = @current_action.execute if @current_action.respond_to?(:execute)
  end

  def move_to_correct_space(screen)
    @current_action.set_cursor(screen)
  end
end
