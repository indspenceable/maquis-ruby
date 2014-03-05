class LordDied < Action
  def initialize
  end

  def draw(window)
    window.draw_game_over
  end

  def key(x)
    puts "KEY"
    `rm #{SAVE_FILE_PATH}`
    exit
    self
  end

  def cancel
    puts "CANCEL"
    `rm #{SAVE_FILE_PATH}`
      exit
    self
  end
end
