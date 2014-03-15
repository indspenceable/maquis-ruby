class Wand
end

class PoisonWand < Wand
  def pretty
    "poison wand"
  end
  def activate!(me, target, level)
    target.buff!('poison', 2, 5)
  end
  def used_up?
    false
  end
  def valid_target?(t)
    true
  end
end

Item.register('poison_wand' => PoisonWand)
