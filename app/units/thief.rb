Thief = create_class('t', "Thief", 5, 5, {
  :max_hp => [40, 70],
  :power => [20, 30],
  :skill => [50, 60],
  :speed => [50, 80], # Wowee!
  :armor => [10, 20],
  :resistance => [10, 35],
}, {
  :max_hp => 14,
  :power  => 2,
  :skill  => 6,
  :speed  => 6,
  :armor  => 0,
  :resistance    => 0,
}, [:swords])
