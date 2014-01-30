Myrmidon = create_class('y', "Myrmidon", {
  :max_hp => [60, 80],
  :power => [20, 30],
  :skill => [50, 70], # Wowee!
  :speed => [50, 70],
  :armor => [10, 20],
  :resistance => [10, 35],
}, {
  :max_hp => 14,
  :power  => 3,
  :skill  => 5,
  :speed  => 5,
  :armor  => 2,
  :resistance => 0,
  :constitution => 5,
}, [
  WieldSwords.new,
])
