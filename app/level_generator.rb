class FakeUnit
  attr_reader :x, :y
  def initialize x, y
    @x, @y = x, y
  end

  def movement_costs
    Hash.new(1).merge({
      '^' => 999
    })
  end

  def team
    1
  end
end

class SoldierTheme
  def pop_klass
    [Soldier, Soldier, Soldier, Soldier, Soldier, Cavalier].shuffle.pop
  end
  def fortune
    "Lots of soldiers! Bring axes."
  end
end

class BrigandTheme
  def pop_klass
    [Brigand, Brigand, Brigand, Brigand, Fighter, Mercenary].shuffle.pop
  end
  def fortune
    "Brigands coming in over the mountains. Sword wielders would be useful here."
  end
end

class BalancedArmyTheme
  def pop_klass
    [Brigand, Soldier, Soldier, Cavalier, Archer, ArmorKnight, Mercenary].shuffle.pop
  end
  def fortune
    "They're sending a balanced army at you. Bring a diversity of weapons in this battle!"
  end
end

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

    def theme
      @theme ||= [
        SoldierTheme.new,
        BrigandTheme.new,
        BalancedArmyTheme.new,
        # [Fighter, Fighter, Fighter, Mercenary, Mercenary, Archer, Cavalier],
        # [Mercenary, Cavalier, ArmorKnight]
      ].shuffle.pop
    end

    def select_enemy_units(difficulty)
      (2 + rand(3)).times.map do |x|
        kl = theme.pop_klass
        lv = 1 + rand(difficulty/2 + 1) + difficulty/2
        kl.new(COMPUTER_TEAM, "Baddie #{x}", lv, false, true)
      end
    end

    def place_units_in_area(units, area, level)
      units.each do |u|
        return false if area.none?
        begin
          u.x, u.y = area.pop
        end while level.map(u.x, u.y) == '^'
      end
    end

    def place_units_in_far_away_circles(level, baddie_units, player_units)
      # now, find some points to center them on. We'll start with just one point for now.
      begin
        px, py, bx, by = rand(MAP_SIZE_X), rand(MAP_SIZE_Y), rand(MAP_SIZE_X) ,rand(MAP_SIZE_Y)
        player_area = Path.discover_paths(FakeUnit.new(px,py), level, 4)
        baddie_area = Path.discover_paths(FakeUnit.new(bx,by), level, 4)
        path_between = Path.find(FakeUnit.new(px,py), bx, by, level, 100, true)
      end while false ||
        player_area.count < player_units.size ||
        baddie_area.count < baddie_units.size ||
        !path_between || path_between.length < min_distance
      player_area.map!(&:last_point)
      baddie_area.map!(&:last_point)
      player_area.shuffle!
      baddie_area.shuffle!
      place_units_in_area(player_units, player_area, level)
      place_units_in_area(baddie_units, baddie_area, level)
      level.units.concat(baddie_units)

      return true
    end

    def fill_in_level(army, difficulty, level)
      baddie_units = select_enemy_units(difficulty)
      player_units = army.units
      success = false
      until success == true
        success = place_units_in_far_away_circles(level, baddie_units, player_units)
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
                  count += 1 if l.map(x+i,y+j) == '^'
                end
              end
              other_map[x][y] = (count >= 5) || (count <= 2 && rand(100)>75) ? '^' : ' '
            end
          end
          l.fill { |x,y| other_map[x][y] }
        end

        l.fill do |x,y|
          next '^' if border?(x,y)

          case other_map[x][y]
          when ' '
            '^'
          when '^'
            rand(100) > 95 ? 'T' : (rand(100) > 95 ? '#' : ' ')
          end
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
        l.fill {|x,y| starting_mountains.include?([x,y]) ? 'T' : ' ' }

        # use cellular attomata to iterate 5 times over this map
        other_map = Array.new(MAP_SIZE_X){ Array.new(MAP_SIZE_Y) }
        3.times do
          (MAP_SIZE_X).times do |x|
            (MAP_SIZE_Y).times do |y|
              next other_map[x][y] = '^' if border?(x,y)
              count = 0
              3.times do |_i|
                i = _i-1
                3.times do |_j|
                  j = _j-1
                  count += 1 if l.map(x+i,y+j) == 'T'
                end
              end
              other_map[x][y] = (count >= 1) && (rand(100) < 25) ? 'T' :  (rand(100) < 10) ? '#' : ' '
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
