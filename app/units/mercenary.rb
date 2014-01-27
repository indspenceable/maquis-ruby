Mercenary = create_class('e', "Mercenary", 5, 6, {
  :max_hp =>[70, 90],
  :power => [40, 60],
  :skill => [20, 50],
  :speed => [20, 50],
  :armor => [10, 30],
}, {
  :max_hp => 16,
  :power  => 4,
  :skill  => 3,
  :speed  => 3,
  :armor  => 4,
  :res    => 0,
}, [:swords])
