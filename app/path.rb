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

  def self.min_dist(_x,_y, list_of_destinations)
    list_of_destinations.map{|x,y| (_x-x).abs + (_y-y).abs}.min || 0
  end

  def self.find(unit, destinations, level, limit=999, enemy_strategy=:block)
    path_base(:find, unit, level, limit, enemy_strategy, destinations)
  end

  def self.discover_paths(unit, level, limit=999, enemy_strategy=:block)
     path_base(:discover, unit, level, limit, enemy_strategy, [])
  end

  def self.path_base(method, unit, level, limit, enemy_strategy, destinations)
    unless [:ignore, :block, :block_seen].include?(enemy_strategy)
      raise "invalid enemy strategy: #{enemy_strategy}"
    end

    # TODO - this should be able to a* (use shortest estimated distance to nearest (x,y) dstination)
    open_list = PQueue.new([Path.new(unit.x,unit.y, level)]) do |a, b|
      b.cost(unit)+min_dist(*b.last_point, destinations) <=> a.cost(unit)+min_dist(*a.last_point, destinations)
    end
    closed_list = []
    while open_list.size > 0
      current_path = open_list.pop
      path_x, path_y = current_path.last_point
      return current_path if (method == :find) && destinations.any? do |(dx,dy)|
        (path_x == dx) && (path_y == dy)
      end
      closed_list << current_path
      paths_to_consider = [
        current_path.dup.add(path_x+1, path_y),
        current_path.dup.add(path_x-1, path_y),
        current_path.dup.add(path_x, path_y+1),
        current_path.dup.add(path_x, path_y-1),
      ]
      paths_to_consider.reject! do |p|
        # reject paths that push us over the limit
        p.cost(unit) > limit ||
        # or, this point is already on the open list
        open_list.to_a.any?{|pp| pp.last_point == p.last_point} ||
        # or, we're not pathing through enemies, and there's an enemy there.
        # or we're not pathing through seen enemies and we can't see that point
        closed_list.any?{|pp| pp.last_point == p.last_point} ||
        (
          (
            (enemy_strategy == :block) ||
            (enemy_strategy == :block_seen && level.see?(*p.last_point))
          ) &&
          level.unit_at(*p.last_point) &&
          level.unit_at(*p.last_point).team != unit.team
        )
      end
      paths_to_consider.each do |p|
        open_list.push p
      end
    end
    closed_list if (method == :discover)
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

  # Assumes adjacency
  def direction_for(cx, cy, nx, ny)

    if nx > cx
      :right
    elsif nx < cx
      :left
    elsif ny > cy
      :down
    else
      :up
    end
  end

  def each_with_direction
    @path.size.times do |i|
      d1 = if i == 0
        :start
      else
        direction_for(*@path[i-1], *@path[i])
      end
      d2 = if i == @path.size-1
        :end
      else
        direction_for(*@path[i], *@path[i+1])
      end
      yield @path[i], :"#{d1}_#{d2}"
    end
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

  def at(i)
    @path[i]
  end
end
