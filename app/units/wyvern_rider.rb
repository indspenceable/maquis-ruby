WyvernRider = create_class('w', 'Wyvern Rider', {
  :max_hp => [50, 90],
  :power  => [40, 65],
  :skill  => [20, 55],
  :speed  => [30, 60],
  :armor  => [30, 60],
  :resistance  => [5, 30],
}, {
  :max_hp => 14,
  :power  => 4,
  :skill  => 2,
  :speed  => 2,
  :armor  => 3,
  :resistance => 0,
  :constitution => 13
}, [
  WieldLances.new,
  PegasusRider.new,
])
