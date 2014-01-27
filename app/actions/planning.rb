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
    if can_recruit
      @menu_items += [@seperator] + army.possible_recruits(difficulty)
    end
    @menu_items += [@seperator, "Fortune Teller", "Next Level"]
    @pending_messages = []
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
    if @pending_messages.any?
      @messages << @pending_messages.shift
      return self
    else
      @messages = []
    end


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
      @pending_messages << @generator.theme.fortune
      @pending_messages += @generator.fog_fortune
      self
    elsif current_item == "Next Level"
      l = @generator.generate(@army, @difficulty+1)
      UnitSelect.new(l.lord.x, l.lord.y, l)
    elsif !@army.units.include?(current_item)
      @army.recruit!(current_item)
      Planning.new(@difficulty, @army, false, @generator)
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
        "#{item.name} (#{item.klass} #{item.level})"
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

  def draw_special(screen)
    screen.messages.set_xy(0,0)
    ms = @messages + (@pending_messages.any?? ["---More---"] : [])
    ms.each_with_index do |message, i|
      screen.messages.set_xy(0, i)
      screen.messages.draw_str(message)
    end
  end

  def cancel
    self
  end
end

