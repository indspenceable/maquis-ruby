PegasusKnight = create_class('g', 'Pegasus Knight', 7, 5, {
  :max_hp => [40, 80],
  :power  => [30, 45],
  :skill  => [40, 65],
  :speed  => [50, 70],
  :armor  => [10, 20],
  # :res    => [25, 35],
}, {
  :max_hp => 14,
  :power  => 2,
  :skill  => 4,
  :speed  => 4,
  :armor  => 1,
  :res    => 3,
}, [:lances], {'^' => 1, 'T' => 1}, [:flying])
