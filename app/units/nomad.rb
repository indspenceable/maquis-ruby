Nomad = create_class('n', "Nomad", {
  :max_hp =>[70, 90],
  :power => [30, 60],
  :skill => [20, 50],
  :speed => [30, 50],
  :armor => [10, 20],
  :resistance => [10, 40],
}, {
  :max_hp => 16,
  :power  => 3,
  :skill  => 3,
  :speed  => 4,
  :armor  => 3,
  :resistance => 0,
  :constitution => 11,
}, [
  Horseback.new,
  WieldBows.new,
])
