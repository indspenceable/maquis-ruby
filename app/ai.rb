class GenericAI
  def score(option, level)
    score_target(option, level) + score_path(option, level)
  end

  def score_target(option, level)
    option.unit.at(*option.path.last_point) do
      if option.target
        [
          score_has_target(option, level),
          score_damage_dealt(option, level),
          score_damage_taken(option, level),
          score_kill(option, level),
          score_death(option, level),
        ].inject(:+)
      else
        0
      end
    end
  end

  def score_has_target(option, level)
    option.target ? has_target_weight : 0
  end

  def score_damage_dealt(option, level)
    (option.unit.power_vs(option.target)) *
    (option.unit.double_attack?(option.target) ? 2 : 1) *
    (option.target.can_hit?(option.unit) ? 1 : 0) *
    (damage_dealt_weight)
  end

  def score_damage_taken(option, level)
    (option.target.power_vs(option.unit)) *
    (option.target.double_attack?(option.unit) ? 2 : 1) *
    (option.target.can_hit?(option.unit) ? 1 : 0) *
    (damage_taken_weight)
  end

  def score_kill(option, level)
    if option.unit.power_vs(option.target) > option.target.hp
      kill_weight
    else
      0
    end
  end

  def score_death(option, level)
    if option.target.power_vs(option.unit) > option.unit.hp
      death_weight
    else
      0
    end
  end

  def score_vs_lord(option, level)
    if option.target.lord?
      vs_lord_weight
    else
      0
    end
  end

  def score_path(option, level)
    [
      score_nearest_opponent(option, level),
      score_distance_travelled(option, level),
      score_distance_from_pack(option, level),
      score_distance_from_player_pack(option, level),
    ].inject(:+)
  end

  def score_nearest_opponent(option, level)
    foes = level.units.select{|u| u.team == PLAYER_TEAM}
    foes.map{|f| Path.dist(*option.path.last_point, f.x, f.y)}.min *
    nearest_opponent_weight
  end

  def score_distance_travelled(option, level)
    option.path.length * distance_travelled_weight
  end

  def score_distance_from_pack(option, level)
    friends = level.units.select{|u| u.team != PLAYER_TEAM} - [option.unit]

    return 0 if friends.length == 1
    ((option.path.last_point[0] -
      round(friends.map(&:x).inject(:+) / friends.count.to_f)).abs +
     (option.path.last_point[1] -
      round(friends.map(&:x).inject(:+) / friends.count.to_f)).abs) *
    distance_from_pack_weight
  end
  def score_distance_from_player_pack(option, level)
    foes = level.units.select{|u| u.team == PLAYER_TEAM}

    ((option.path.last_point[0] -
      round(foes.map(&:x).inject(:+) / foes.count.to_f)).abs +
     (option.path.last_point[1] -
      round(foes.map(&:y).inject(:+) / foes.count.to_f)).abs) *
      distance_from_player_pack_weight
  end

  def method_missing(sym, *args)
    if sym.to_s =~ /.*_weight/
      puts "Undefined weight method: #{sym}"
      self.class.__send__(:define_method, sym){ 0 }
      return 0
    else
      super(sym, *args)
    end
  end

  # def self.method_missing(sym, *args)
  #   if sym.to_s =~ /.*_weight/
  #     define_method(sym){ args.first }
  #   else
  #     super(sym, *args)
  #   end
  # end
end

class ZerkAI < GenericAI
  def has_target_weight
    1000
  end
  def nearest_opponent_weight
    -10
  end
  def vs_lord_weight
    10
  end
end

class CautiousAI < GenericAI
  # def has_target_weight
  #   100
  # end
  # def damage_taken_weight
  #   -3
  # end
  def has_target_weight
    30
  end

  def damage_dealt_weight
    1
  end

  def damage_taken_weight
    -1
  end

  def distance_from_pack_weight
    -2
  end

  def nearest_opponent_weight
    -2
  end
end

# class ZerkAI
#   def score(option, friends, foes)
#     x,y = option.path.last_point
#     (option.target ? 1000 : 0) -
#     foes.map{|f| Path.dist(x,y, f.x, f.y)}.min*10 -
#     option.path.length
#   end
# end

# class AttackWhenInRangeAI
#   def score(option, friends, foes)
#     x,y = option.path.last_point
#     (option.target ? 1000 : 0) -
#     option.path.length
#   end
# end
