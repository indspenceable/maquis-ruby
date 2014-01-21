require './lib/permissive_fov'
require './lib/display/region'
require './lib/display/screen'
require './lib/actions/base'
require './lib/actions/menu'
require './lib/actions/map_select'
require './lib/actions/move'
require './lib/actions/confirm_move'
require './lib/actions/planning'
require './lib/actions/enemy_turn'
require './lib/level_generator'
require './lib/level'
require './lib/names'
require './lib/items/weapon'
require './lib/units/base'
require './lib/player_army'

#constants go here too, cause yolo

MAP_SIZE_X = 40
MAP_SIZE_Y = 20

PLAYER_TEAM = 0
COMPUTER_TEAM = 1

module GameRunner
  def setup
    # setup the first level of the game. Woot.
    # level = Level.generate(PlayerArmy.new(3), 1)
    # @x, @y = 1, 1
    # @current_action = MapSelect.new(3, 3, level)
    @current_action = Planning.new(0, PlayerArmy.new(3))
  end

  def display(screen)
    @current_action.display(screen)
    finish_display
  end

  def execute
    @current_action = @current_action.execute if @current_action.respond_to?(:execute)
  end

  def move_to_correct_space(screen)
    @current_action.set_cursor(screen)
  end
end
