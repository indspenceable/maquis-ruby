class Level
  include PermissiveFieldOfView
  attr_reader :map, :units, :log
  def initialize(w,h)
    @w,@h = w,h
    @units = []
    @log = []
  end

  def calculate_fov(units)
    @lit = []
    units.each do |u|
      do_fov( u.x, u.y, 5 )
    end
    @lit
  end
  def blocked?(x,y)
    @map[x][y] == '#'
  end
  def light(x,y)
    @lit << [x,y]
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

  def self.generate(player_units)
    l = Level.new(MAP_SIZE_X, MAP_SIZE_Y)
    l.fill do |x,y|
      border?(x,y) ? '#' :
        rand(100) < 45   ? '#' : ' '
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
          other_map[x][y] = (count >= 5) || (count <= 2 && rand(100)>75) ? '#' : ' '
        end
      end
      l.fill { |x,y| other_map[x][y] }
    end

    #ensure connectivity
    open_count = 0
    connected_count = nil
    l.map.each_with_index do |col, x|
      col.each_with_index do |tile,y|
        if tile == ' '
          open_count += 1
          connected_count ||= Path.discover_paths(Struct.new(:x,:y).new(x,y), l, 100).count
        end
      end
    end
    return generate(player_units) if connected_count < open_count-10

    # Now to generate baddies
    # first, pick a baddie theme
    # TODO baddie themes

    baddie_units = (7 + rand(7)).times.map do |x|
      kl = case rand(3)
      when 0
        ArmorKnight
      when 1
        Archer
      when 2
        Cavalier
      end
      stats = {}
      Unit::STATS.each{|stat| stats[stat] = rand(5)+3}
      kl.new(COMPUTER_TEAM, "Baddie #{x}", 0, 0, stats)
    end


    # now, find some points to center them on. We'll start with just one point for now.
    begin
      px, py, bx, by = rand(MAP_SIZE_X), rand(MAP_SIZE_Y), rand(MAP_SIZE_X) ,rand(MAP_SIZE_Y)
      player_area = Path.discover_paths(Struct.new(:x,:y).new(px,py), l, 3)
      baddie_area = Path.discover_paths(Struct.new(:x,:y).new(bx,by), l, 3)
      path_between = Path.find(Struct.new(:x,:y).new(px,py), bx, by, l, 100)
    end while false ||
      player_area.count < player_units.size ||
      baddie_area.count < baddie_units.size ||
      !path_between || path_between.length < 30

    player_area.map!(&:last_point)
    baddie_area.map!(&:last_point)
    player_area.shuffle!
    baddie_area.shuffle!

    player_units.each do |u|
      l.units << u
      u.x, u.y = player_area.pop
    end

    # puts "baddie_area is #{baddie_area.inspect}"
    baddie_units.each do |u|
      l.units << u
      u.x, u.y = baddie_area.pop
    end

    l
  end
end
