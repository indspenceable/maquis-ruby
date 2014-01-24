class MenuAction < Action
  def initialize choices
    @choices = choices
    @index = 0
  end
  def key(c)
    if c == KEYS[:down]
      @index += 1
    elsif c == KEYS[:up]
      @index -=1
    elsif c == KEYS[:accept]
      return action!
    end
    @index = @index % @choices.length
    self
  end
  def draw_special(screen)
    @choices.each_with_index do |choice, i|
      screen.info.set_xy(0, 17+i)
      screen.info.draw_str *string_and_color[choice]
    end
  end
  def set_cursor(screen)
    screen.info.set_xy(0, 17+@index)
  end
  def action!
    send @choices[@index]
  end
end
