Nomad = create_class('n', "Nomad", 7, 11, {
  :max_hp =>[70, 90],
  :power => [30, 60],
  :skill => [20, 50],
  :speed => [30, 50],
  :armor => [10, 20],
}, {
  :max_hp => 16,
  :power  => 3,
  :skill  => 3,
  :speed  => 4,
  :armor  => 3,
  :res    => 0,
}, [:bows], {'T' => 3}, [:horse])
