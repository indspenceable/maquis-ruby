class AttackExecutor < Action
  attr_reader :level

  def initialize unit, target, level, next_state
    @unit, @target, @level, @next_state = unit, target, level, next_state
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
        raise "lord died!"
      elsif @level.units.none?{|u| u.team == COMPUTER_TEAM } && @level.goal == :kill_enemies
        Planning.new(@level.difficulty, @level.army.tap(&:next_level!))
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
