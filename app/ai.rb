class AI
  def score (option, friends, foes)
    raise "not a valid AI strategy!"
  end
end

class ZerkAI
  def score(option, friends, foes)
    x,y = option.path.last_point
    (option.target ? 1000 : 0) -
    foes.map{|f| Path.dist(x,y, f.x, f.y)}.min*10 -
    option.path.length
  end
end

class AttackWhenInRangeAI
  def score(option, friends, foes)
    x,y = option.path.last_point
    (option.target ? 1000 : 0) -
    option.path.length
  end
end
