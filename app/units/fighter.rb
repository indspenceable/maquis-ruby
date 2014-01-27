Fighter = create_class('f', 'Fighter', 5, 13, {
  :max_hp => [75, 95],
  :power => [50, 60],
  :skill => [30, 45],
  :speed => [20, 35],
  :armor => [20, 30],
  :resistance => [5, 25],
}, {
  :max_hp => 18,
  :power  => 5,
  :skill  => 2,
  :speed  => 2,
  :armor  => 4,
  :resistance    => 0,
}, [:axes])
