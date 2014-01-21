Cavalier = create_class('c', "Cavalier", 7, 11, {
  :max_hp =>[70, 90],
  :power => [30, 60],
  :skill => [20, 50],
  :speed => [20, 50],
  :armor => [20, 40],
}, {
  :max_hp => 16,
  :power  => 3,
  :skill  => 3,
  :speed  => 4,
  :armor  => 3,
  :res    => 0,
}, [:swords, :lances])
