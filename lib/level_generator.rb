module LevelGenerator
  class Base
    def border?(x,y)
      x == 0 || x == MAP_SIZE_X-1 || y == 0 || y == MAP_SIZE_Y-1
    end

    def generate(army, difficulty)
      # Now to generate baddies
      # first, pick a baddie theme
      # TODO baddie themes
      fill_in_level(army, difficulty, generate_map)
    end

    def generate_map
      # might not generate a good map the first time, so loop until we do.
      while true
        # start with an empy level, fill it with tiles randomly
        l = Level.new(MAP_SIZE_X, MAP_SIZE_Y)
        l.fill do |x,y|
          border?(x,y) ? '^' :
            rand(100) < 45   ? '^' : ' '
        end

        # use cellular attomata to iterate 5 times over this map
        other_map = Array.new(MAP_SIZE_X){ Array.new(MAP_SIZE_Y) }
        5.times do
          (MAP_SIZE_X).times do |x|
            (MAP_SIZE_Y).times do |y|
              next other_map[x][y] = '^' if border?(x,y)
              count = 0
              3.times do |_i|
                i = _i-1
                3.times do |_j|
                  j = _j-1
                  count += 1 if l.map[x+i][y+j] == '^'
                end
              end
              other_map[x][y] = (count >= 5) || (count <= 2 && rand(100)>75) ? '^' : ' '
            end
          end
          l.fill { |x,y| other_map[x][y] }
        end

        #ensure connectivity, recurse if needed
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
        return l if connected_count < open_count-10
      end
    end

    def select_theme
      [
        [Soldier, Soldier, Soldier, Soldier, Soldier, Cavalier]
        # [Fighter, Fighter, Fighter, Mercenary, Mercenary, Archer, Cavalier],
        # [Mercenary, Cavalier, ArmorKnight]
      ].shuffle.pop
    end

    def select_enemy_units(difficulty)
      theme = select_theme
      (2 + rand(3)).times.map do |x|
        kl = theme.shuffle.pop
        lv = 1 + rand(difficulty/2 + 1) + difficulty/2
        kl.new(COMPUTER_TEAM, "Baddie #{x}", lv, false, true)
      end
    end

    def place_units_in_far_away_circles(level, baddie_units, player_units)
      # now, find some points to center them on. We'll start with just one point for now.
      begin
        px, py, bx, by = rand(MAP_SIZE_X), rand(MAP_SIZE_Y), rand(MAP_SIZE_X) ,rand(MAP_SIZE_Y)
        player_area = Path.discover_paths(Struct.new(:x,:y).new(px,py), level, 3)
        baddie_area = Path.discover_paths(Struct.new(:x,:y).new(bx,by), level, 3)
        path_between = Path.find(Struct.new(:x,:y).new(px,py), bx, by, level, 100)
      end while false ||
        player_area.count < player_units.size ||
        baddie_area.count < baddie_units.size ||
        !path_between || path_between.length < min_distance

      player_area.map!(&:last_point)
      baddie_area.map!(&:last_point)
      player_area.shuffle!
      baddie_area.shuffle!

      player_units.each do |u|
        u.x, u.y = player_area.pop
      end

      # puts "baddie_area is #{baddie_area.inspect}"
      baddie_units.each do |u|
        level.units << u
        u.x, u.y = baddie_area.pop
      end
    end

    def fill_in_level(army, difficulty, level)
      baddie_units = select_enemy_units(difficulty)
      player_units = army.units
      place_units_in_far_away_circles(level, baddie_units, player_units)

      # set important level stats
      level.goal = goal
      level.army = army
      level.difficulty = difficulty
      level.fog_of_war = fog_of_war
      level
    end
  end

  class KillEnemies < Base
    def min_distance
      10
    end

    def goal
      :kill_enemies
    end

    def fog_of_war
      true
    end
  end
end
