require 'curses'

KEYS = if ARGV[0] == 'vi'
  {
    :left => 'h',
    :right => 'l',
    :down => 'j',
    :up => 'k',
    :cancel => 27,
    :accept => 'a',
  }
else
  {
    :left => 'a',
    :right => 'd',
    :down => 's',
    :up => 'w',
    :cancel => 27,
    :accept => ' ',
  }
end

BLUE = 1
RED = 2
GREEN = 3
FOG_COLOR = 4

TEAM_TO_COLOR = {
  0 => GREEN,
  1 => RED
}

require './lib/game_runner'

class CursesDisplay
  include GameRunner

  def initialize
    setup
  end

  def finish_display
    Curses::refresh
  end

  #TODO this is not ideal but it lives here so fuck it.
  def key(c)
    (('a'..'z').to_a + [' ']).each do |str|
      c = str if str.unpack('C')[0] == c
    end
    if c == KEYS[:cancel]
      @current_action = @current_action.cancel
    else
      @current_action = @current_action.key(c)
    end
  end
end

begin
  Screen.open do |s|
    display = CursesDisplay.new
    loop do
      display.execute
      display.display(s)
      display.move_to_correct_space(s)
      display.key(Curses::getch)
    end
  end
end

