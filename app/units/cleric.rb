Cleric = create_class('c', "Cleric", 5, 3, {
  :max_hp =>[30, 55],
  :power => [40, 60],
  :skill => [20, 40],
  :speed => [20, 40],
  :armor => [10, 30],
}, {
  :max_hp => 15,
  :power  => 2,
  :skill  => 2,
  :speed  => 2,
  :armor  => 1,
  :res    => 3,
}, [:staves])
