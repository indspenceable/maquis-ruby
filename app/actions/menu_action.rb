class MenuAction < Action
  def initialize choices
    @choices = choices
    @index = 0
  end

  def key(c)
    if c == KEYS[:down]
      @index += 1
    elsif c == KEYS[:up]
      @index -= 1
    elsif c == KEYS[:accept]
      return action!
    end
    @index = @index % @choices.length
    self
  end

  def action!
    send @choices[@index]
  end
end
