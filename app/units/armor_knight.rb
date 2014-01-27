ArmorKnight = create_class('k', "Knight", 4, 14, {
  :max_hp =>[80, 100],
  :power => [30, 60],
  :skill => [20, 40],
  :speed => [20, 40],
  :armor => [30, 60],
  :resistance => [10, 25],
}, {
  :max_hp => 18,
  :power  => 4,
  :skill  => 2,
  :speed  => 2,
  :armor  => 5,
  :resistance    => 0,
}, [:lances])
