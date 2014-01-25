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

  def vertical_offset
    15
  end

  def draw_special(screen)
    @choices.each_with_index do |choice, i|
      screen.info.set_xy(0, vertical_offset+i)
      screen.info.draw_str *string_and_color[choice]
    end
  end
  def set_cursor(screen)
    screen.info.set_xy(0, vertical_offset+@index)
  end
  def action!
    send @choices[@index]
  end

  def strings_and_color
    raise 'abstact method #strings_and_color unimplemented in #{self.class.name}'
  end
end
