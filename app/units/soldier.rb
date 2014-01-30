Soldier = create_class('s', "Soldier", {
  :max_hp =>[60, 60],
  :power => [20, 20],
  :skill => [20, 20],
  :speed => [20, 20],
  :armor => [20, 20],
  :resistance => [20, 20],
}, {
  :max_hp => 20,
  :power  => 3,
  :skill  => 0,
  :speed  => 2,
  :armor  => 1,
  :resistance => 0,
  :constitution => 6,
}, [
  WieldLances.new,
])
