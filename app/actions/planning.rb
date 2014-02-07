# Between level planning -
# Lets you do stuff like:
#  * trade items
#  * visit the fortune teller (pay to know about the next level) (?)
#  * recruit units?
class Planning < Action
  def initialize(difficulty, army, can_recruit = true, generator = [LevelGenerator::Mountain.new].sample)
    @difficulty, @army = difficulty, army
    @index = 0
    @seperator = "---"
    @menu_items = army.units
    # if can_recruit
    #   @menu_items += [@seperator] + army.possible_recruits(difficulty)
    # end
    @menu_items += [@seperator, "Fortune Teller", "Next Level"]
    @messages = []
    @generator = generator
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
    elsif c == KEYS[:info]
      if current_item.is_a?(Unit)
        if @army.units.include?(current_item)
          return UnitInfo.new(current_item, @army.units, self)
        end
      end
    elsif c == KEYS[:accept]
      return action!
    end
    @index = @index % @menu_items.length
    self
  end

  def action!
    # If we add more actions to this, we should probably just split them out
    # into their own clases.
    if current_item == "Fortune Teller"
      # raise "Fortune teller isn't implemented at this point in time"
      @messages << @generator.terrain_fortune
      @messages << @generator.theme.fortune
      @messages += @generator.fog_fortune
      self
    elsif current_item == "Next Level"
      l = @generator.generate(@army, @difficulty+1)
      @army.units.each{|x| x.current_level = l}
      UnitSelect.new(l.lord.x, l.lord.y, l)
    elsif !@army.units.include?(current_item)
      @army.units << current_item
      Planning.new(@difficulty, @army, false, @generator)
    else
      Trade.new(current_item, @army, self) { self }
    end
  end

  def units_for_info_panel
    if current_item.is_a? Unit
      [current_item]
    else
      []
    end
  end

  def display(window)
    window.character_list_for_planning(@menu_items, current_item)
    window.add_messages(@messages) if @messages.any?
    @messages = []
  end

  def cancel
    self
  end
end

