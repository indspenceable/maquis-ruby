require './app/permissive_fov'
require './app/display/region'
require './app/display/screen'
require './app/skill'
require './app/actions/base'
require './app/actions/menu_action'
require './app/actions/menu_actions/turn_menu'
require './app/actions/map_action'
require './app/actions/map_actions/unit_select'
require './app/actions/map_actions/move'
require './app/actions/attack_executor'
require './app/actions/menu_actions/attack_target_select'
require './app/actions/menu_actions/attack_weapon_select'
require './app/actions/menu_actions/confirm_move'
require './app/actions/menu_actions/inventory'
require './app/actions/unit_info'
require './app/actions/planning'
require './app/actions/enemy_turn'
require './app/actions/highlight_enemy_moves'
require './app/actions/trade'
require './app/level_generator'
require './app/level'
require './app/names'
require './app/items/weapon'
require './app/items/vulnerary'
require './app/units/base'
require './app/player_army'

#constants go here too, cause yolo

MAP_SIZE_X = 40
MAP_SIZE_Y = 20

PLAYER_TEAM = 0
COMPUTER_TEAM = 1

module GameRunner
  attr_reader :current_action

  def setup(action=nil)
    @current_action = action || Planning.new(-1, PlayerArmy.new(6))
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
