require 'curses'

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


Screen.open do |s|
  display = CursesDisplay.new
  loop do
    display.execute
    display.display(s)
    display.move_to_correct_space(s)
    display.key(s.win.getch)
  end
end

