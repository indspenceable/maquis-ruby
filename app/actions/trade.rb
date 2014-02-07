class Trade
  def initialize(u1, u2, prev, &blk)
    @u1, @u2 = u1, u2
    @prev_action = prev
    @index = 0
    @cu, @ou = u1, u2
    toggle_current_unit! unless @cu.inventory.any?

    @i1, @i2 = @u1.inventory.dup, @u2.inventory.dup
    @next_action = blk
  end

  def draw(window)
    window.show_trade(@u1, @u2, highlighted_item)
  end

  def key(c)
    case c
    when KEYS[:left], KEYS[:right]
      toggle_current_unit!
    when KEYS[:down]
      next!
    when KEYS[:up]
      prev!
    when KEYS[:accept]
      select!
    end
    self
  end

  def cancel
    # neither unit has gotten more items, meaning net of 0 items traded
    if (@i1 - @u1.inventory) + (@i2 - @u2.inventory) == []
      @prev_action
    else
      @next_action.call
    end
  end

  private

  def highlighted_item
    @cu.inventory[@index]
  end

  def toggle_current_unit!
    if @ou.inventory.any?
      @cu, @ou = @ou, @cu
      @index = @cu.inventory.length - 1 if @index >= @cu.inventory.length
    end
  end

  def next!
    return unless @cu.inventory.any?
    @index += 1
    @index = @index % @cu.inventory.length
  end

  def prev!
    return unless @cu.inventory.any?
    @index -= 1
    @index = @index % @cu.inventory.length
  end

  def select!
    return unless @cu.inventory.any?
    @ou.inventory << @cu.inventory.delete_at(@index)
    if @cu.inventory.any?
      @index -= 1 if @index == @cu.inventory.size
    else
      toggle_current_unit!
    end
  end
end
