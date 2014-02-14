require 'matrix'
class LevelBalancer
  def initialize
    # process every class first.
    seeds.each do |l|
      l.each do |k,_,_|
        location_in_equation(k)
      end
    end

    m1 = (Matrix.rows(seeds.length.times.map do |i|
          level_to_equation(i)
        end))
    if seeds.length != level_to_equation(0).length
      puts @locations.keys.inspect
      raise "#{seeds.length} levels, when we need #{level_to_equation(0).length}"
    end
    m2 = Matrix.rows(seeds.length.times.map{|x| [1000*(x+1)]})
    vals = (m1.inverse*m2).to_a.map(&:first).map(&:to_i)
    puts @locations.keys.zip(vals).inspect
  end

  def location_in_equation(str)
    @count ||= 0
    @locations ||= {}
    unless @locations[str]
      @locations[str] = @count
      @count += 1
    end
    @locations[str]
  end

  def level_to_equation(index)
    ary = Array.new(@locations.keys.length*1){0}
    seeds[index].each do |kl, level, count|
      loc = location_in_equation(kl)
      # ary[loc] += count
      ary[loc+1-1] += count * level
    end
    ary
  end

  def seeds
    # list of levels
    # each level is a list of [Class, level, count] tuples.
    [
      # level 1
      [
        ['Brigand', 5, 1],
        ['Brigand', 3, 1],
        ['Brigand', 2, 2],
        ['Brigand', 1, 4],
        ['Archer',  1, 1],
        ['Archer',  2, 1],
      ],
      [
        ['Brigand', 9, 1],
        # ['Soldier', 2, 2],
        # ['Soldier', 1, 2],
        ['Brigand', 1, 2],
        # ['Mercenary', 1, 2],
        # ['Mercenary', 2, 1],
        ['Brigand', 3, 1],
        # ['Fighter', 1, 1],
        ['Archer', 2, 2],
        # ['Fighter', 2, 1],
      ],
      [
        ['Knight', 13, 1], # steel lance
        ['Archer', 3, 1],
        # ['Soldier', 2, 3],
        # ['Mercenary', 2, 1],
        ['Archer', 4, 1], # steel bow
        ['Brigand', 1, 1],
        # ['Myrmidon', 3, 1], # killing edge
        # ['Soldier', 2, 1],
        ['Archer', 2, 2],
        #reinforcements
      ],
      [
        ['Cavalier', 14, 1],
        # ['Myrmidon', 3, 1],
        ['Archer', 3, 2],
        ['Cavalier', 1, 3],
        ['Cavalier', 3, 6],
        ['Cavalier', 2, 4],
        # ['Soldier', 3, 3],
        ['Knight', 2, 1],

        #reinforcement
        ['Brigand', 3, 4],
      ],
      [
        ['Knight', 18, 1],
        # ['Myrmidon', 2, 1],
        # ['Myrmidon', 5, 1],
        # ['Mercenary', 2, 1],
        # ['Mercenary', 3, 1],
        # ['Mercenary', 4, 1],
        # ['Mercenary', 5, 3],
        ['Archer', 5, 1],
        ['Archer', 6, 1],
        ['Cavalier', 3, 3],
        ['Cavalier', 4, 1],
        ['Cavalier', 5, 1],
        # ['Mage', 8, 1],
        # ['Mage', 9, 1],
        # ['Thief', 3, 1],
      ],
      [
        ['Knight', 21, 1],
        ['Archer', 3, 1],
        ['Archer', 4, 1],
        ['Archer', 5, 1],
        ['Archer', 6, 6],
        ['Archer', 7, 2],
        ['Archer', 8, 4],
        # ['Fighter', 4, 1],
        ['Knight', 3, 1],
        ['Knight', 4, 4],
        ['Knight', 5, 3],
        # ['Shaman', 2, 1],
        # reinforcements
        ['Cavalier', 5, 6],
        # ['Shaman', 5, 1]
      ],
      [
        # ['Shaman', 18, 1],
        ['Archer', 4, 1],
        # ['Mercenary', 5, 2],
        # ['Mercenary', 6, 4],
        # ['Mercenary', 8, 2],
        # ['Shaman', 4, 1],
        # ['Shaman', 6, 2],
        # ['Shaman', 7, 5],
        #reinforcements
        # ['Myrmidon', 4, 2],
        # ['Mercenary', 4, 3],
        # ['Shaman', 5, 1],
        # ['Shaman', 6, 2],
        # ['Mercenary', 5, 4],
        # ['Myrmidon', 5, 1],
        # ['Pegasus Knight', 5, 2]
      ],

    ]
  end
end
LevelBalancer.new
