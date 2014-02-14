class FakeUnit
  attr_reader :x, :y
  def initialize x, y
    @x, @y = x, y
  end

  def movement_costs
    Hash.new(1).merge({
      :mountain => 999,
      :wall => 999
    })
  end

  def team
    1
  end
end

class Theme
  def pop_klass(_)
    klasses.shuffle.pop
  end
end

class SoldierTheme < Theme
  def klasses
    [Soldier, Soldier, Soldier, Soldier, Soldier, Cavalier]
  end

  def fortune
    "Lots of soldiers! Bring axes."
  end

  def team
    "Brigand"
  end

  def boss_klass(_)
    ArmorKnight
  end
end

class RANDOMTHEME < Theme
  def klasses
    [
      Fighter,
      ArmorKnight,
      Mage,
      Archer,
      Myrmidon,
      Thief,
      Monk,
      Shaman,
      Soldier,
      Brigand,
    ]
  end

  def fortune
    "Lots of fighters! Bring swords."
  end

  def team
    "Brigand"
  end

  def boss_klass(_)
    Fighter
  end
end

class BrigandTheme < Theme
  def klasses
    [Brigand, Brigand, Brigand, Brigand, Fighter, Mercenary]
  end

  def fortune
    "Brigands coming in over the mountains. Sword wielders would be useful here."
  end

  def team
    "Brigand"
  end

  def boss_klass(_)
    Fighter
  end
end

class BalancedArmyTheme < Theme
  def klasses
    [Brigand, Soldier, Soldier, Cavalier, Archer, ArmorKnight, Mercenary]
  end

  def fortune
    "They're sending a balanced army at you. Bring a diversity of weapons in this battle!"
  end

  def team
    "Brigand"
  end


  def boss_klass(_)
    Mercenary
  end
end

module LevelGenerator
  class Base
    def border?(x,y,l)
      x == 0 || x == l.map_size_x-1 || y == 0 || y == l.map_size_y-1
    end

    def generate(army, difficulty)
      fill_in_level(army, difficulty, generate_map)
    end

    def theme
      @theme ||= [
        # SoldierTheme.new,
        # BrigandTheme.new,
        # BalancedArmyTheme.new,
        RANDOMTHEME.new,
      ].shuffle.pop
    end

    def select_enemy_units(difficulty)
      # how many units?
      # 13 - 20
      enemy_count = number_of_enemy_units

      # choose a unit for the boss.
      enemy_levels = enemy_count.times.map do |x|
        difficulty * 2 + 1
      end

      # a bunch of times, select 2 enemies, and adjust them evenly
      (rand(10)+5).times do
        e1 = rand(enemy_count)
        e2 = rand(enemy_count)
        next unless enemy_levels[e1] > 1
        enemy_levels[e1] -= 1
        enemy_levels[e2] += 1
      end

      return [
        theme.boss_klass(difficulty).new(
          COMPUTER_TEAM,
          "Count #{Names.generate}",
          (difficulty+1)*5,
          false,
          true)
      ] + enemy_levels.map do |lv|
        theme.pop_klass(difficulty).new(COMPUTER_TEAM, theme.team, lv, false, true)
      end
    end

    def place_units_in_area(units, area, level)
      units.each do |u|
        begin
          return false if area.none?
          u.x, u.y = area.pop
        end while level.map(u.x, u.y) != :plains
      end
    end

    def place_units_in_far_away_circles(level, baddie_units, player_units)
      # now, find some points to center them on. We'll start with just one point for now.
      begin
        px, py = rand(level.map_size_x), rand(level.map_size_y)
        bx, by = rand(level.map_size_x), rand(level.map_size_y)
        player_area = Path.discover_paths(FakeUnit.new(px,py), level, 4)
        baddie_area = Path.discover_paths(FakeUnit.new(bx,by), level, 4)
        path_between = Path.find(FakeUnit.new(px,py), bx, by, level, 70, :ignore)
      end while false ||
        map(px, py) == :wall || map(bx, by) == :wall
        player_area.count < player_units.size ||
        baddie_area.count < baddie_units.size ||
        !path_between || path_between.length < min_distance
      player_area.map!(&:last_point)
      baddie_area.map!(&:last_point)
      player_area.shuffle!
      baddie_area.shuffle!
      return false unless place_units_in_area(player_units, player_area, level)
      return false unless place_units_in_area(baddie_units, baddie_area, level)
      level.units.concat(baddie_units.each{|u| u.current_level = level})

      return true
    end

    def place_units_with_baddies_scattered(level, baddie_units, player_units)
      baddie_boss = baddie_units.shift
      whole_map = level.map_size_x.times.to_a.product(level.map_size_y.times.to_a)

      begin
        px, py, bx, by = rand(level.map_size_x), rand(level.map_size_y), rand(level.map_size_x) ,rand(level.map_size_y)
        player_area = Path.discover_paths(FakeUnit.new(px,py), level, 4)
        baddie_area = whole_map.select{|(x,y)| level.map(x,y) == :plains} - player_area
      end while player_area.count < player_units.size ||
                baddie_area.count < baddie_units.size ||
                level.map(px, py) != :plains ||
                level.map(bx, by) != :plains ||
                (px == bx && py == by)

      player_area.map!(&:last_point)
      # incase theres possible movement off of the map
      player_area &= whole_map
      # remove the boss' location from the baddies area.
      baddie_area.delete([bx,by])
      player_area.shuffle!
      baddie_area.shuffle!
      baddie_area -= Path.discover_paths(FakeUnit.new(px,py), level, 7).map(&:last_point)

      return false unless place_units_in_area(player_units, player_area, level)
      return false unless place_units_in_area(baddie_units, baddie_area, level)
      baddie_boss.x, baddie_boss.y = bx, by
      level.units.concat((baddie_units + [baddie_boss]).each{|u| u.current_level = level})

      return true
    end

    def fill_in_level(army, difficulty, level)
      baddie_units = select_enemy_units(difficulty)
      player_units = army.units
      success = false
      tries = 0

      until place_units_with_baddies_scattered(level, baddie_units, player_units)
      end

      # set important level stats
      level.goal = goal
      level.army = army
      level.difficulty = difficulty
      level.fog_of_war = fog_of_war
      level
    end

    def fog_fortune
      if fog_of_war
        ["A heavy fog is setting in... Consider bringing thieves or torches."]
      else
        []
      end
    end
  end

  class Mountain < Base
    def min_distance_x(l)
      l.map_size_x/1.2
    end
    def min_distance_y(l)
      l.map_size_y/1.2
    end
    def num_points(l)
      l.map_size_y/2
    end
    def decay_iterations(l)
      l.map_size_y/6
    end

    def number_of_enemy_units
      1 + rand(7)
    end


    def generate_map
      # might not generate a good map the first time, so loop until we do.
      while true
        # start with an empy level, fill it with tiles randomly
        l = Level.new(
          20+rand(20),
          15+rand(15)
        )
        l.fill { :mountain }


        # selet a number of random points. Ensure they've got a total distance
        # large enough. Draw lines of plains between them.
        c = false
        points = []

        until c
          points = num_points(l).times.map{ [rand(l.map_size_x), rand(l.map_size_y)] }.uniq
          c = (points.map(&:first).max-points.map(&:first).min) > min_distance_x(l) &&
              (points.map(&:last).max-points.map(&:last).min) > min_distance_y(l) &&
              points.length == num_points(l)
        end

        (points.count-1).times do |i|
          (fx, fy), (lx, ly) = points[i], points[i+1]
          fx += 1 if (fx - lx).abs == (fy - ly).abs
          100.times do |j|
            cx = round(fx + (lx - fx)* (j / 100.0))
            cy = round(fy + (ly - fy)* (j / 100.0))
            l.set_map(cx,cy,:plains) if cx < l.map_size_x && cy < l.map_size_y
          end
        end

        # Erode away from plains.
        other_map = Array.new(l.map_size_x){ Array.new(l.map_size_y) }
        decay_iterations(l).times do
          (l.map_size_x).times do |x|
            (l.map_size_y).times do |y|
              count = 0
              3.times do |_i|
                i = _i-1
                3.times do |_j|
                  j = _j-1
                  count += 1 if l.map(x+i,y+j) == :mountain
                end
              end

              other_map[x][y] =
              if l.map(x,y) != :mountain
                :plains
              elsif border?(x,y,l)
                if rand < count/4.0
                  :mountain
                else
                  :plains
                end
              elsif rand < (1.05 * count/8.0)**1.2 # (slghtly over a 1 in count chance)
                :mountain
              else
                :plains
              end
            end
          end
          l.fill { |x,y| other_map[x][y] }
        end

        new_walls = []
        (l.map_size_x).times do |x|
          (l.map_size_y).times do |y|
            next unless l.map(x,y) == :mountain
            count = 0
            5.times do |_i|
              i = _i-2
              5.times do |_j|
                j = _j-2
                if [:mountain, :wall].include?(l.map(x+i, y+j))
                  count += 1
                end
              end
            end
            new_walls << [x,y] if count >= 23
          end
        end
        new_walls.each do |(x,y)|
          l.set_map(x,y,:wall) if rand(100) > 20
        end

        # TODO - on the ground, fill in roads + forest.
        new_forests = []
        new_forts = []
        (l.map_size_x).times do |x|
          (l.map_size_y).times do |y|
            next unless l.map(x,y) == :plains
            r = rand(100)
            case
            when r < 6
              new_forests << [x,y]
            when r < 8
              new_forts << [x,y]
            end
          end
        end
        new_forts.each do |(x,y)|
          l.set_map(x,y,:fort)
        end
        new_forests.each do |(x,y)|
          l.set_map(x,y,:forest)
        end

        return l
      end
    end

    def terrain_fortune
      "Your next fight will take place in a mountain pass. Mountaineers might let you avoid some chokepoints..."
    end

    def goal
      :kill_enemies
    end

    def fog_of_war
      false
    end

    def min_distance
      10
    end
  end

  class Forest < Base
    def min_distance
      10
    end

    def generate_map
      # might not generate a good map the first time, so loop until we do.
      while true
        # start with an empy level, fill it with tiles randomly
        l = Level.new(MAP_SIZE_X, MAP_SIZE_Y)
        starting_mountains = 15.times.map{[rand(MAP_SIZE_X), rand(MAP_SIZE_Y)]}
        l.fill {|x,y| starting_mountains.include?([x,y]) ? :forest : :plains }

        # use cellular attomata to iterate 5 times over this map
        other_map = Array.new(MAP_SIZE_X){ Array.new(MAP_SIZE_Y) }
        3.times do
          (MAP_SIZE_X).times do |x|
            (MAP_SIZE_Y).times do |y|
              next other_map[x][y] = :mountain if border?(x,y,l)
              count = 0
              3.times do |_i|
                i = _i-1
                3.times do |_j|
                  j = _j-1
                  count += 1 if l.map(x+i,y+j) == :forest
                end
              end
              other_map[x][y] = (count >= 1) && (rand(100) < 25) ? :forest :  (rand(100) < 10) ? :fort : :plains
            end
          end
          l.fill { |x,y| other_map[x][y] }
        end

        return l
      end
    end

    def terrain_fortune
      "Your next fight will take place in a dense forest. Calvalry will have a hard time omving around."
    end

    def goal
      :kill_enemies
    end

    def fog_of_war
      false
    end
  end
end
