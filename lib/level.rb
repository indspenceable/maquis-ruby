# MAP_SIZE_X = 20
# MAP_SIZE_Y = 40

class Level
  attr_reader :map, :units, :log
  def initialize(w,h)
    @w,@h = w,h
    @units = []
    @log = []
  end
  def fill
    @map = Array.new(@w) do |x|
      Array.new(@h) do |y|
        yield x, y
      end
    end
  end
  def unit_at(x,y)
    units.find{|c| c.x == x && c.y == y}
  end

  def self.border?(x,y)
    x == 0 || x == MAP_SIZE_X-1 || y == 0 || y == MAP_SIZE_Y-1
  end

  def self.generate()
    l = Level.new(MAP_SIZE_X, MAP_SIZE_Y)
    l.fill do |x,y|
      border?(x,y) ? '#' :
        rand(100) < 45   ? '#' : '.'
    end
    other_map = Array.new(MAP_SIZE_X){ Array.new(MAP_SIZE_Y) }
    5.times do
      (MAP_SIZE_X).times do |x|
        (MAP_SIZE_Y).times do |y|
          next other_map[x][y] = '#' if border?(x,y)
          count = 0
          3.times do |_i|
            i = _i-1
            3.times do |_j|
              j = _j-1
              count += 1 if l.map[x+i][y+j] == '#'
            end
          end
          other_map[x][y] = (count >= 5) || (count <= 2 && rand(100)>75) ? '#' : '.'
        end
      end
      l.fill { |x,y| other_map[x][y] }
    end

    #ensure connectivity
    open_count = 0
    connected_count = nil
    l.map.each_with_index do |col, x|
      col.each_with_index do |tile,y|
        if tile == '.'
          open_count += 1
          connected_count ||= Path.discover_paths(Struct.new(:x,:y).new(x,y), l, 100).count
        end
      end
    end
    return generate if connected_count < open_count-10

    l
  end
end
