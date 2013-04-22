class Path
  def self.dist(x1,y1,x2,y2)
    (x1-x2).abs + (y1-y2).abs
  end
  def self.find(unit, x2, y2, level, limit=99)

    open_list = [Path.new(unit.x,unit.y, level)]
    closed_list = []
    i = 0
    while open_list.any?
      i+=1
      # open_list.sort{|b,a| dist(x2,y2, *a.last_point) <=> dist(x2,y2, *b.last_point)}
      c = open_list.shift
      cx,cy = c.last_point
      return c if cx == x2 && cy == y2
      next if c.length > limit || level.map { |e|  }[cx][cy] != '.'
      closed_list << c
      [
        c.dup.add(cx+1, cy),
        c.dup.add(cx-1, cy),
        c.dup.add(cx, cy+1),
        c.dup.add(cx, cy-1),
      ].each do |p|
        unless (closed_list + open_list).any?{|pp| p.last_point == pp.last_point} ||
          level.unit_at(*p.last_point) && level.unit_at(*p.last_point).team != unit.team
          open_list << p
        end
      end
    end
    nil
  end
  def self.discover_paths(unit, level, limit=99)

    open_list = [Path.new(unit.x, unit.y, level)]
    closed_list = []
    i = 0
    while open_list.any?
      i+=1
      # open_list.sort{|b,a| dist(x2,y2, *a.last_point) <=> dist(x2,y2, *b.last_point)}
      c = open_list.shift
      cx,cy = c.last_point
      # return puts(i)||Curses::getch||c if cx == x2 && cy == y2
      next if c.length > limit+1 || level.map { |e|  }[cx][cy] != '.'
      closed_list << c
      [
        c.dup.add(cx+1, cy),
        c.dup.add(cx-1, cy),
        c.dup.add(cx, cy+1),
        c.dup.add(cx, cy-1),
      ].each do |p|
        unless (closed_list + open_list).any?{|pp| p.last_point == pp.last_point} ||
          level.unit_at(*p.last_point) && level.unit_at(*p.last_point).team != unit.team
          open_list << p
        end
      end
    end
    closed_list
  end
  def initialize (x, y, level)
    @level = level
    @sx, @sy = x,y
    @path = [[x,y]]
  end
  def dup
    p = Path.new(@sx, @sy, @level)
    p.instance_variable_set(:@path, @path.map(&:dup))
    p
  end
  def cost
    @path.length
  end
  def add x,y
    @path << [x,y]
    self
  end
  def trim_to(x,y)
    @path = @path.take_while{|xx,yy| (xx!=x) || (yy!=y)} + [[x,y]]
  end
  def last_point
    (@path.last || [@sx, @sy])
  end
  def each &blk
    @path.each(&blk)
  end
  def include?(x,y)
    @path.include?([x,y])
  end
  def length
    @path.length
  end
end
