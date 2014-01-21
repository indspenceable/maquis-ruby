# Between level planning -
# Lets you do stuff like:
#  * trade items
#  * visit the fortune teller (pay to know about the next level) (?)
#  * recruit units?
class Planning < Action
  def initialize(difficulty, army, can_recruit = true)
    @difficulty, @army = difficulty, army
    @index = 0
    @seperator = "---"
    @menu_items = army.units
    if can_recruit
      @menu_items += [@seperator] + army.possible_recruits(difficulty)
    end
    @menu_items += [@seperator, "Fortune Teller", "Next Level"]
  end

  def current_item
    @menu_items[@index]
  end
  def next!
    @index += 1
    while current_item == @seperator
      @index += 1
    end
  end
  def prev!
    @index -= 1
    while current_item == @seperator
      @index -= 1
    end
  end
  def key(c)
    if c == KEYS[:down]
      next!
    elsif c == KEYS[:up]
      prev!
    elsif c == KEYS[:accept]
      return action!
    end
    @index = @index % @menu_items.length
    self
  end

  def action!
    if current_item == "Fortune Teller"
      raise "Fortune teller isn't implemented at this point in time"
    elsif current_item == "Next Level"
      l = Level.generate(@army, @difficulty+1)
      MapSelect.new(l.lord.x, l.lord.y, l)
    elsif !@army.units.include?(current_item)
      @army.recruit!(current_item)
      Planning.new(@difficulty, @army, false)
    else
      self
    end
  end

  def units_for_info_panel
    if current_item.is_a? Unit
      [current_item]
    else
      []
    end
  end

  def display_map(screen)
    # this is going to be different than other ations! woot.
    screen.map.clear
    screen.map.set_xy(0,0)
    @menu_items.each_with_index do |item, index|
      str = if item.is_a?(Unit)
        "#{item.name} (#{item.klass})"
      else
        item
      end
      screen.map.set_xy(0,index)
      if current_item == item
        screen.map.draw_str "* #{str}"
      else
        screen.map.draw_str "  #{str}"
      end
    end
  end
  def set_cursor(screen)
    screen.map.set_xy(0,@index)
  end
  def draw(screen)
  end
end

