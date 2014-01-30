class Archer < Unit
  glyph 'a'
  klass "Archer"
  def class_growths
    {
      :max_hp =>[50, 70],
      :power => [10, 40],
      :speed => [20, 70],
      :skill => [40, 70],
      :armor => [10, 30],
      :resistance => [10, 30],
    }
  end

  def starting_stats
    {
      :max_hp => 14,
      :power  => 3,
      :skill  => 5,
      :speed  => 4,
      :armor  => 2,
      :resistance => 0,
      :constitution => 6,
    }
  end

  def starting_skills
    [
      WieldBows.new,
    ]
  end
end

