Cavalier = create_class('h', "Cavalier", 7, 11, {
  :max_hp =>[70, 90],
  :power => [30, 60],
  :skill => [20, 50],
  :speed => [20, 50],
  :armor => [20, 40],
  :resistance => [10, 25],
}, {
  :max_hp => 16,
  :power  => 3,
  :skill  => 3,
  :speed  => 4,
  :armor  => 3,
  :resistance    => 0,
}, [:swords, :lances], {:forest => 3}, [:horse])
