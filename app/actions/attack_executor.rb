# This runs an attack. Every time it runs #auto:
# if animating something (@animating isn't nil) - return
# if we're not finished, run the next step of battle.
# if neither of those are true, then determine the correct next state.

class AttackExecutor < Action
  attr_reader :level

  def initialize unit, target, level, &next_state
    @unit, @target, @level, @next_state = unit, target, level, next_state
    @messages = []
    @current_state = :attack
  end

  def next_phase_of_battle
    @current_state = self.send(@current_state)
  end

  def units_for_info_panel
    [@unit, @target]
  end

  def draw(window)
    draw_map(window)
    draw_units(@level.units, window)
  end

  def auto
    return @animation if @animation
    unless @current_state == :done
      next_phase_of_battle
      return self
    end

    done

    if @level.lord.nil?
      # Kill our savegame.
      `rm #{SAVE_FILE_PATH}`
      raise "lord died!"
    elsif @level.units.none?{|u| u.team == COMPUTER_TEAM }
      @level.finish_turn(COMPUTER_TEAM)
    else
      @unit.action_available = false
      @next_state.call
    end
  end

  def key(c)
    self
  end

  private

  def both_alive?
    @unit.alive? && @target.alive?
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
      crit = !!(rand(100) < attacker.crit_chance)
      damage_dealt = attacker.hit(defender, crit ? 3 : 1)
      @animation = AttackAnimation.new(
        attacker,
        defender,
        "#{damage_dealt}#{crit ? '!' : ''}",
        @level
      ) do
        @animation = nil
        self
      end
    else
      @animation = AttackAnimation.new(
        attacker,
        defender,
        :miss,
        @level
      ) do
        @animation = nil
        self
      end
    end
  end

  def no_hit_experience
    1
  end

  def hit_experience(me, vs)
    # this doesn't ammend level for promoted units
    (31 + vs.exp_level - me.exp_level) / 3
  end

  def kill_experience(me, vs)
    base = ((vs.exp_level * 3) + 0) - ((me.exp_level * 3) + 0)
    if base <= 0
      ((vs.exp_level * 3) + 0) - ((me.exp_level * 3) + 0)/2
    else
      base
    end
  end


  def gain_exp(me, vs)
    return unless me.alive?
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
        [kill_experience(me, vs) + 20 + hit_experience(me, vs),1].max
      end
    else
      no_hit_experience
    end
  end

  def determine_next_state(current_state)
    return :death unless both_alive?
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
    determine_next_state(:double_attack)
  end

  def double_counter
    combat_round(@target, @unit, @messages)
    determine_next_state(:double_counter)
  end

  def death
    if @unit.alive?
      # @animation = [@target, @unit, :death]
      @animation = DeathAnimation.new(@target, @level) { @animation = nil; self }
      @level.units.delete(@target)
    else
      # @animation = [@unit, @target, :death]
      @animation = DeathAnimation.new(@unit, @level) { @animation = nil; self }
      @level.units.delete(@unit)
    end
    :done
  end

  def done
    a,b = @unit, @target
    a,b = b,a if @target.team == PLAYER_TEAM
    gain_exp(a, b)
    @finished = true
    @finished_animating = false
  end

end
