require 'pqueue'

class Path
  def self.unit_dist(u1,u2)
    dist(u1.x,u1.y,u2.x,u2.y)
  end

  def self.dist(x1,y1,x2,y2)
    (x1-x2).abs + (y1-y2).abs
  end

  def self.default_movement_costs
    {
      :plains => 1,
      :forest => 2,
      :fort => 2,
      :mountain => 999,
      :wall => 999
    }
  end

  def self.find(unit, dx, dy, level, limit=998, path_through_enemies=false)
    open_list = PQueue.new([Path.new(unit.x,unit.y, level)]) {|a, b| b.cost(unit) <=> a.cost(unit) }
    closed_list = []
    while open_list.size > 0
      current_path = open_list.pop
      path_x, path_y = current_path.last_point
      return current_path if path_x == dx && path_y == dy
      closed_list << current_path
      paths_to_consider = [
        current_path.dup.add(path_x+1, path_y),
        current_path.dup.add(path_x-1, path_y),
        current_path.dup.add(path_x, path_y+1),
        current_path.dup.add(path_x, path_y-1),
      ]
      paths_to_consider.reject! do |p|
        p.cost(unit) > limit ||
        open_list.to_a.any?{|pp| pp.last_point == p.last_point} ||
        closed_list.any?{|pp| pp.last_point == p.last_point} ||
        (
          !path_through_enemies &&
          level.unit_at(*p.last_point) &&
          level.unit_at(*p.last_point).team != unit.team
        )
      end
      paths_to_consider.each do |p|
        open_list.push p
      end
    end
    nil
  end

  def self.discover_paths(unit, level, limit=998, path_through_enemies=false)
    open_list = PQueue.new([Path.new(unit.x,unit.y, level)]) {|a, b| b.cost(unit) <=> a.cost(unit) }
    closed_list = []
    while open_list.size > 0
      current_path = open_list.pop
      path_x, path_y = current_path.last_point
      closed_list << current_path
      paths_to_consider = [
        current_path.dup.add(path_x+1, path_y),
        current_path.dup.add(path_x-1, path_y),
        current_path.dup.add(path_x, path_y+1),
        current_path.dup.add(path_x, path_y-1),
      ]
      paths_to_consider.reject! do |p|
        p.cost(unit) > limit ||
        open_list.to_a.any?{|pp| pp.last_point == p.last_point} ||
        closed_list.any?{|pp| pp.last_point == p.last_point} ||
        (
          !path_through_enemies &&
          level.unit_at(*p.last_point) &&
          level.unit_at(*p.last_point).team != unit.team
        )
      end
      paths_to_consider.each do |p|
        open_list.push p
      end
    end
    closed_list
  end

  def self.discover_unblocked_paths(unit, level, limit=99)
    discover_paths(unit,level,limit).reject do |p|
      u = level.unit_at(*p.last_point)
      u && u != unit
    end
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

  def cost(unit)
    costs = @path.map do |x,y|
      unit.movement_costs[@level.map(x,y)]
    end
    costs.shift
    costs.inject(0,&:+)
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
  def each_but_last
    (@path.size - 1).times do |i|
      yield @path[i]
    end
  end
  def each_but_first
    (@path.size - 1).times do |i|
      yield @path[i+1]
    end
  end
  def include?(x,y)
    @path.include?([x,y])
  end
  def any?(&blk)
    @path.any?(&blk)
  end
  def length
    @path.length
  end
end
