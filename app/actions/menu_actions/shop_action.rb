class ShopAction < MenuAction
  def initialize(unit, level, shop, previous_action)
    @unit, @level, @previous_action = unit, level, previous_action
    @shop = shop
    @item_list = @shop.items
    super(@item_list.map(&:pretty))
    @made_purchase = false
  end

  def can_afford_current_item?
    @item_list[@index].price <= @level.army.money
  end

  def action!
    # override action!
    if can_afford_current_item?
      @level.army.money -= @item_list[@index].price
      puts "YOU NOW HAVE #{@level.army.money} MONEY"
      @unit.inventory << @item_list.delete_at(@index)
      @made_purchase = true
      @choices = @item_list.map(&:pretty)
      @index -= 1 if @index == @choices.length
      return cancel if @choices == []
    end
    self
  end

  def cancel
    if @made_purchase
      @unit.action_available = false
      @level.next_action(@unit.x, @unit.y)
    else
      @previous_action
    end
  end

  def draw(window)
    draw_map(window)
    draw_all_units(window)
    window.draw_menu(@choices, @index)
  end
end
