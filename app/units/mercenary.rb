Mercenary = create_class('e', "Mercenary", {
  :max_hp =>[70, 90],
  :power => [40, 60],
  :skill => [20, 50],
  :speed => [20, 50],
  :armor => [10, 30],
  :resistance => [10, 40],
}, {
  :max_hp => 16,
  :power  => 4,
  :skill  => 3,
  :speed  => 3,
  :armor  => 4,
  :resistance => 1,
  :constitution => 6,
}, [
  WieldSwords.new,
])
