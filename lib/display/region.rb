class Region
  # attr_reader :x, :y, :w, :h
  def initialize x, y, w, h
    @x, @y, @w, @h = x, y, w, h
  end
  def set_xy(x, y)
    Curses::setpos(@y+y, @x+x)
  end
  def draw_str(str, color=0, attrs=0)
    Curses::attron(Curses::color_pair(color)| attrs |Curses::A_NORMAL) do
      Curses::addstr(str)
    end
  end
  def fill(chr, color)
    @w.times do |a|
      @h.times do |b|
        set_xy(a, b)
        draw_str(chr, color)
      end
    end
  end
  def clear
    fill(' ', 0)
  end
end
