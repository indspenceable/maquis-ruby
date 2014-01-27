Shaman = create_class('b', "Shaman", 5, 3, {
  :max_hp =>[30, 60],
  :power => [40, 65],
  :skill => [20, 45],
  :speed => [10, 40],
  :armor => [10, 30],
}, {
  :max_hp => 15,
  :power  => 3,
  :skill  => 1,
  :speed  => 1,
  :armor  => 1,
  :res    => 3,
}, [:dark])
