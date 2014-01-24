Archer = create_class('a', "Archer", 5, 6, {
  :max_hp =>[50, 70],
  :power => [10, 40],
  :speed => [20, 70],
  :skill => [40, 70],
  :armor => [10, 30],
}, {
  :max_hp => 14,
  :power  => 3,
  :skill  => 5,
  :speed  => 4,
  :armor  => 2,
  :res    => 0,
}, [:bows]
)

class Archer
  def initialize *args
    super
    @inventory = [IronBow.new].shuffle
  end
end

