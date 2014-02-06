#!/usr/bin/env ruby
require 'gosu'
require 'yaml'

KEYS = if ARGV[0] == 'vi'
  {
    :left => 'h',
    :right => 'l',
    :down => 'j',
    :up => 'k',
    :cancel => 27,
    :accept => 'a',
    :info => 's',
  }
else
  {
    :left => Gosu::KbLeft,
    :right => Gosu::KbRight,
    :down => Gosu::KbDown,
    :up => Gosu::KbUp,
    :cancel => Gosu::KbX,
    :accept => Gosu::KbZ,
    :info => Gosu::KbI,
  }
end

require './app/game_runner'
SAVE_FILE_PATH = File.expand_path(File.join('~', '.tarog'))
previous_save = if File.exists?(SAVE_FILE_PATH)
  YAML.load(File.read(SAVE_FILE_PATH))
end

class GosuDisplay < Gosu::Window
  include GameRunner

  def initialize(previous_save)
    super(640, 480, false)
    setup(nil)
    @font = Gosu::Font.new(self, "courier", 12)
  end

  def update
  end

  def button_down(id)
    old_action = @current_action
    if id == KEYS[:cancel]
      @current_action = @current_action.cancel
    else
      puts (KEYS.invert)[id]
      @current_action = @current_action.key(id)
    end
    @current_action.precalculate! unless old_action == @current_action
  end

  def draw
    @main_screen_draw = false
    @current_action.display(self)
  end

  def main_screen_draw
    raise "Already drew the main screen!" if @main_screen_draw
    @main_screen_draw = true
  end

  TILE_SIZE_X = 16
  TILE_SIZE_Y = 16

  def draw_char_at(x, y, c, highlight_squares)
    draw_quad(
      (x+0)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, Gosu::Color::WHITE,
      (x+1)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, Gosu::Color::WHITE,
      (x+1)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, Gosu::Color::WHITE,
      (x+0)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, Gosu::Color::WHITE, 1)
  end

  def draw_terrain(x,y, tile, highlight_squares, seen)
    c = case tile
    when :plains
      Gosu::Color::YELLOW
    when :forest
      Gosu::Color::GREEN
    when :mountain
      Gosu::Color::RED
    else
      Gosu::Color::BLUE
    end
    draw_quad(
      (x+0)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, c,
      (x+1)*TILE_SIZE_X, (y+0)*TILE_SIZE_Y, c,
      (x+1)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, c,
      (x+0)*TILE_SIZE_X, (y+1)*TILE_SIZE_Y, c, 0)
  end

  def draw_cursor(x,y)
    c = Gosu::Color::CYAN
    draw_quad(
      (x+0)*TILE_SIZE_X+1, (y+0)*TILE_SIZE_Y+1, c,
      (x+1)*TILE_SIZE_X-1, (y+0)*TILE_SIZE_Y+1, c,
      (x+1)*TILE_SIZE_X-1, (y+1)*TILE_SIZE_Y-1, c,
      (x+0)*TILE_SIZE_X+1, (y+1)*TILE_SIZE_Y-1, c, 3)
  end

  def display_character_info(u1, u2, ignore_range)
  end

  def show_trade(u1, u2, highlighted_item)
  end

  def extended_character_info(unit)
  end

  def draw_messages(ms)
    ms.each do |m|
      puts Array(m).first
    end
  end

  def character_list_for_planning(menu_items, current_item)
    menu_items.each_with_index do |m,i|
      @font.draw(m.inspect, 10, i*16, 1)
      if m == current_item
        draw_quad(
          0+0 , i*16, Gosu::Color::WHITE,
          0+0 , i*16+16, Gosu::Color::WHITE,
          0+16, i*16+16, Gosu::Color::WHITE,
          0+16, i*16, Gosu::Color::WHITE,
          1)
      end
    end
  end
end

DISPLAY = GosuDisplay.new(previous_save)

def save_game
  File.open(SAVE_FILE_PATH, 'w+', 0644) do |f|
    f << YAML.dump(DISPLAY.current_action)
  end
end

DISPLAY.show

