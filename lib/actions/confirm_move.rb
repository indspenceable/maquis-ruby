class AttackExecutor
  def initialize unit, target, level, next_state
    @unit = unit
    @target = target
    @level = level

    @next_state = next_state

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

  def combat_round(attacker, defender, messages)
    return unless attacker.weapon && attacker.weapon.in_range?(Path.unit_dist(attacker, defender))
    if rand(100) < attacker.accuracy(defender)
      hit = defender.take_hit_from(attacker)
      messages << "#{attacker.name} hits #{defender.name}, for #{hit} damage."
      check_life
    else
      messages << "#{attacker.name} misses!"
    end
  end

  # TODO this doesn't work in ruby 1.8.7
  # We should move away from this stupid generator style anyway
  def execute
    @generator ||= Enumerator.new do |g|
      # Do the fight! first round
      if @unit.weapon
        combat_round(@unit, @target, @messages)
      end
      if @target.weapon
        g << nil
        combat_round(@target, @unit, @messages)
      end
      if @unit.double_attack?(@target) && @unit.weapon
        g << nil
        combat_round(@unit, @target, @messages)
      elsif @target.double_attack?(@unit) && @target.weapon
        g << nil
        combat_round(@target, @unit, @messages)
      end
      raise StopIteration
    end

    @finished = false
    begin
      @generator.next
    rescue StopIteration
      @unit.action_available = false
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
      @next_state
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

class AttackWeaponSelect < MenuAction
  def initialize unit, target, level, path, prev_action
    @unit = unit
    @level = level
    @target = target
    @prev_action = prev_action
    @path = path

    @available_weapons = @unit.weapons_that_hit_at(Path.dist(*@path.last_point, @target.x, @target.y))
    super((0...@available_weapons.size).to_a)
  end
  def string_and_color
    @available_weapons.map(&:class).map(&:name)
  end
  def unit_for_map_highlighting
    nil
  end
  def units_for_info_panel
    [@unit, @target]
  end
  def key *args
    rtn = super
    equip_selected_weapon!
    rtn
  end
  def equip_selected_weapon!
    @unit.equip!(@available_weapons[@index])
  end
  def action!
    AttackExecutor.new(@unit, @target, @level, MapSelect.new(@unit.x, @unit.y, @level))
  end
  def cancel
    @prev_action
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
    # MoveAndAttackAttack.new(@unit, @targets[@index], @level, @path)
    AttackWeaponSelect.new(@unit, @targets[@index], @level, @path, self)
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
    if enemies_in_range.any? && unit.weapon
      opts << :attack
    end
    opts << :confirm
    opts << :cancel
    super(opts)
    @start_x, @start_y = @unit.x, @unit.y
    @unit.x, @unit.y = @path.last_point
  end
  def units_for_info_panel
    [@unit]
  end
  def enemies_in_range
    @enemies_in_range ||= @level.units.select do |u|
      u.team != @unit.team &&
      @unit.available_weapons.any?{|w| w.in_range?(Path.dist(*@path.last_point, u.x, u.y))}
    end
    # [
    #   @level.unit_at(@path.last_point[0]+1,@path.last_point[1]),
    #   @level.unit_at(@path.last_point[0]-1,@path.last_point[1]),
    #   @level.unit_at(@path.last_point[0],@path.last_point[1]+1),
    #   @level.unit_at(@path.last_point[0],@path.last_point[1]-1),
    # ].compact.select{|u| u.team != @unit.team}
  end
  def attack
    AttackTargetSelect.new(@unit, @level, enemies_in_range, @path, self)
  end

  def draw(screen)
    @path.each_but_last do |x,y|
      screen.map.set_xy(x,y)
      screen.map.draw_str('*', BLUE)
    end
    super
  end

  def confirm
    @unit.action_available = false
    MapSelect.new(@unit.x, @unit.y, @level)
  end
  def cancel
    @unit.x, @unit.y = @start_x, @start_y
    @prev_action
  end
  def unit_for_map_highlighting
    nil
  end
end
