class AttackExecutor
  attr_reader :level

  def initialize unit, target, level, next_state
    @unit = unit
    @target = target
    @level = level

    @next_state = next_state

    @messages = []
  end

  def check_life(add_messages=true)
    unless @unit.alive?
      @messages << "#{@unit.name} dies!" if add_messages
      @level.units.delete(@unit)
      return false
    end
    unless @target.alive?
      @messages << "#{@target.name} dies!" if add_messages
      @level.units.delete(@target)
      return false
    end
    true
  end

  def can_attack(attacker, defender)
    attacker.weapon && attacker.weapon.in_range?(Path.unit_dist(attacker, defender))
  end

  def record_hit(u)
    @hits ||= {}
    @hits[u] = true
  end
  def has_hit?(u)
    @hits ||= {}
    @hits[u]
  end

  def combat_round(attacker, defender, messages)
    if rand(100) < attacker.accuracy(defender)
      record_hit(attacker)
      hit = defender.take_hit_from(attacker)
      messages << "#{attacker.name} hits #{defender.name}, for #{hit} damage."
      check_life
    else
      messages << "#{attacker.name} misses!"
    end
  end

  def no_hit_experience
    1
  end
  def hit_experience(me, vs)
    # this doesn't ammend level for promoted units
    (31 + vs.level - me.level) / 3
  end
  def kill_experience(me, vs)
    ((vs.level * 3) + 0) - #class relative power, ammend for promoted units
    ((me.level * 3) + 0)
  end


  def gain_exp(me, vs)
    exp = [determine_exp_to_gain(me, vs),1].max
    @messages << "#{me.name} gains #{exp} exp."
    level_up_stats_gained = me.gain_experience(exp)
    if level_up_stats_gained
      stats_gain_string = level_up_stats_gained.any? ? "(#{level_up_stats_gained.join('/')})" : ''
      @messages << "#{me.name} gains a level! #{stats_gain_string}"
    end
  end

  def determine_exp_to_gain(me, vs)
    if has_hit?(me)
      if vs.alive?
        hit_experience(me, vs)
      else
        [kill_experience(me, vs) + 20,0].max + hit_experience(me, vs)
      end
    else
      no_hit_experience
    end
  end

  def determine_next_state(current_state)
    return :done unless check_life(false)
    case current_state
    when :attack
      return :counter if can_attack(@target, @unit)
      return :double_attack if @unit.double_attack?(@target)
      return :double_counter if @target.double_attack?(@unit) && can_attack(@target, @unit)
    when :counter
      return :double_attack if @unit.double_attack?(@target)
      return :double_counter if @target.double_attack?(@unit) && can_attack(@target, @unit)
    end
    :done
  end

  def execute
    @current_state ||= :attack
    @current_state = self.send(@current_state)
    done if @current_state == :done
    self
  end

  def attack
    combat_round(@unit, @target, @messages)
    determine_next_state(:attack)
  end
  def counter
    combat_round(@target, @unit, @messages)
    determine_next_state(:counter)
  end
  def double_attack
    combat_round(@unit, @target, @messages)
    :done
  end
  def double_counter
    combat_round(@target, @unit, @messages)
    :done
  end
  def done
    a,b = @unit, @target
    a,b = b,a if @target.team == PLAYER_TEAM
    gain_exp(a, b)
    @unit.action_available = false
    @finished = true
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
      # Did the players lord die?
      if @level.lord.nil?
        exit
      elsif @level.units.none?{|u| u.team == COMPUTER_TEAM }
        # heal up all units
        @level.units.each do |u|
          u.heal
          u.action_available = true
        end
        l = Level.generate(@level.army.tap(&:next_level), @level.difficulty+1)
        return MapSelect.new(l.lord.x, l.lord.y, l)
      else
        @next_state
      end
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
  attr_reader :level

  def initialize unit, target, level, path, prev_action
    @unit = unit
    @level = level
    @target = target
    @prev_action = prev_action
    @path = path

    @available_weapons = @unit.weapons_that_hit_at(Path.dist(@target.x, @target.y, *@path.last_point))
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
  attr_reader :level

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
  attr_reader :level

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
      @unit.available_weapons.any?{|w| w.in_range?(Path.dist(u.x, u.y, *@path.last_point))}
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
