require 'curses'
require 'pry'
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
    :left => Curses::Key::LEFT,
    :right => Curses::Key::RIGHT,
    :down => Curses::Key::DOWN,
    :up => Curses::Key::UP,
    :cancel => 'x',
    :accept => 'z',
    :info => 'i',
  }
end

BLUE = 1
RED = 2
GREEN = 3
YELLOW = 4
FOG_COLOR = 5

TEAM_TO_COLOR = [
  GREEN,
  RED,
]

require './app/game_runner'
SAVE_FILE_PATH = File.expand_path(File.join('~', '.tarog'))
previous_save = YAML.load(File.read(SAVE_FILE_PATH)) rescue nil

class CursesDisplay
  include GameRunner
  alias_method :initialize, :setup

  def finish_display
    Curses::refresh
  end

  #TODO this is not ideal but it lives here so fuck it.
  def key(c)
    (('a'..'z').to_a + [' ']).each do |str|
      c = str if str.unpack('C')[0] == c
    end
    # TODO - this is ugly.
    if c == KEYS[:cancel]
      @current_action = @current_action.cancel
    else
      @current_action = @current_action.key(c)
    end
  end
end

DISPLAY = CursesDisplay.new(previous_save)

def save_game
  File.open(SAVE_FILE_PATH, 'w+', 0644) do |f|
    f << YAML.dump(DISPLAY.current_action)
  end
end

Screen.open do |s|
  loop do
    DISPLAY.execute
    Curses::curs_set(0)
    DISPLAY.display(s)
    DISPLAY.move_to_correct_space(s)
    save_game
    Curses::curs_set(1)
    DISPLAY.key(s.win.getch)
  end
end

