class Screen
  attr_reader :map, :messages, :info, :full
  attr_reader :win
  def self.open
    Curses::init_screen
    begin
      Curses::cbreak
      Curses::noecho
      Curses::refresh
      Curses::start_color

      # INIT colors
      Curses::init_pair(BLUE, Curses::COLOR_BLUE, Curses::COLOR_BLACK)
      Curses::init_pair(RED, Curses::COLOR_RED, Curses::COLOR_BLACK)
      Curses::init_pair(GREEN, Curses::COLOR_GREEN, Curses::COLOR_BLACK)
      Curses::init_pair(YELLOW, Curses::COLOR_YELLOW, Curses::COLOR_BLACK)
      Curses::init_pair(FOG_COLOR, Curses::COLOR_BLACK, Curses::COLOR_WHITE)

      raise "Must give a block!" unless block_given?
      yield Screen.new
    ensure
      Curses::close_screen
    end
  end
  def initialize
      @win = Curses::stdscr
      @win.keypad(true)
      @map      = Region.new(0, 0, MAP_SIZE_X, MAP_SIZE_Y)
      @info     = Region.new(MAP_SIZE_X + 1, 0,
        Curses::cols-MAP_SIZE_X-1, MAP_SIZE_Y)
      @messages = Region.new(0, MAP_SIZE_Y+1,
        Curses::cols, Curses::lines-MAP_SIZE_Y+1)
      @full     = Region.new(0, 0, Curses::cols, Curses::lines)
  end
end
