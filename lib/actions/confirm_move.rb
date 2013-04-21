class MoveAndAttackAttack
  def initialize unit, target, level, path
    @unit = unit
    @target = target
    @level = level
    @path = path

    @messages = []
  end

  def check_life
    unless @unit.alive?
      @messages << "#{@unit.name} dies!"
      @level.units.delete(@unit)
      raise StopIteration
    end
    unless @target.alive?
      @messages << "#{@target.name} dies!"
      @level.units.delete(@target)
      raise StopIteration
    end
  end

  def execute
    @generator ||= Enumerator.new do |g|
      # Move the unit, if they're moving
      @unit.x, @unit.y = @path.last_point
      # Do the fight! first round
      hit = @target.take_hit(@unit.power_vs(@target))
      @messages << "#{@unit.name} attacks #{@target.name}, for #{hit} damage."
      check_life
      g << nil

      hit = @unit.take_hit(@target.power_vs(@unit))
      @messages << "#{@target.name} attacks #{@unit.name}, for #{hit} damage."
      check_life

      if @unit.double_attack?(@target)
        g << nil
        hit = @target.take_hit(@unit.power_vs(@target))
        @messages << "#{@unit.name} attacks #{@target.name}, for #{hit} damage."
        check_life
      elsif @target.double_attack?(@unit)
        g << nil
        hit = @unit.take_hit(@target.power_vs(@unit))
        @messages << "#{@target.name} attacks #{@unit.name}, for #{hit} damage."
        check_life
      end
      @unit.action_available = false
      raise StopIteration
    end

    @finished = false
    begin
      @generator.next
    rescue StopIteration
      @finished = true
    end
    self
  end
  def draw(screen)
    screen.messages.set_xy(0,0)
    @messages.each_with_index do |message, i|
      screen.messages.set_xy(0, i)
      screen.messages.draw_str(message)
    end
  end
  def units_for_info_panel
    [@unit, @target]
  end
  def key(c)
    if @finished
      MapSelect.new(@unit.x, @unit.y, @level)
    else
      self
    end
  end
  def set_cursor(screen)
    return
  end

  def unit_for_map_highlighting
    nil
  end
end

class AttackTargetSelect < MenuAction
  def initialize unit, level, targets, path, prev_action
    @unit = unit
    @level = level
    @targets = targets
    @prev_action = prev_action
    @path = path
    super Array.new(@targets.length){:confirm}
  end
  def draw(screen)
  end
  def set_cursor(screen)
    screen.map.set_xy(@targets[@index].x, @targets[@index].y)
  end
  def units_for_info_panel
    [@unit, @targets[@index]]
  end
  def confirm
    MoveAndAttackAttack.new(@unit, @targets[@index], @level, @path)
  end
  def cancel
    @prev_action
  end
  def unit_for_map_highlighting
    nil
  end
end
class ConfirmMove < MenuAction
  def string_and_color
    {
      :attack => ["Attack", BLUE],
      :confirm => ["Move", GREEN],
      :cancel => ["Cancel", RED]
    }
  end


  def initialize(unit, path, level, prev_action)
    @level = level
    @unit = unit
    @prev_action = prev_action
    @path = path
    opts = []
    if adjacent_enemies.any?
      opts << :attack
    end
    opts << :confirm
    opts << :cancel
    super(opts)
  end
  def units_for_info_panel
    [@unit]
  end
  def adjacent_enemies
    [
      @level.unit_at(@path.last_point[0]+1,@path.last_point[1]),
      @level.unit_at(@path.last_point[0]-1,@path.last_point[1]),
      @level.unit_at(@path.last_point[0],@path.last_point[1]+1),
      @level.unit_at(@path.last_point[0],@path.last_point[1]-1),
    ].compact.select{|u| u.team != @unit.team}
  end
  def attack
    AttackTargetSelect.new(@unit, @level, adjacent_enemies, @path, self)
  end
  def confirm
    @unit.x, @unit.y = @path.last_point
    @unit.action_available = false
    MapSelect.new(@unit.x, @unit.y, @level)
  end
  def cancel
    @prev_action
  end
  def unit_for_map_highlighting
    nil
  end
end
