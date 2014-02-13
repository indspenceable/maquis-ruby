# Create
# * precalculate - does the first attack.
# * call draw until the animation is done. This will set finished_animating
#    to true, eventually, and then do the next attack
# * when doing an attack, it will always set @current_hit to something.
# * if there's ever a case where @current_hit is nil, then auto will move to
# the correct next state
#
# Actaully doing attacks
# #execute will do the next one, if we're not already one.

class AttackExecutor < Action
  attr_reader :level

  def initialize unit, target, level, &next_state
    @unit, @target, @level, @next_state = unit, target, level, next_state
    @messages = []
  end

  def execute
    return if @current_state == :done
    @current_state ||= :attack
    @current_state = self.send(@current_state)
    done if @current_state == :done
  end

  def units_for_info_panel
    [@unit, @target]
  end

  def draw(window)
    draw_map(window)
    draw_units(@level.units - [@unit, @target], window)

    if @current_hit
      if window.draw_battle_animation(*@current_hit)
        @current_hit = nil
        @finished_animating = true
        execute
        self
      else
        @finished_animating = false
      end
    end
  end

  def precalculate!
    execute
  end

  def auto
    return self if @current_hit
    if @level.lord.nil?
      # Kill our savegame.
      `rm #{SAVE_FILE_PATH}`
      raise "lord died!"
    elsif @level.units.none?{|u| u.team == COMPUTER_TEAM }
      @level.finish_turn(COMPUTER_TEAM)
    else
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

      @current_hit = [attacker, defender, damage_dealt]
    else
      @current_hit = [attacker, defender, :miss]
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
    ((vs.exp_level * 3) + 0) - #class relative power, ammend for promoted units
    ((me.exp_level * 3) + 0)
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
      @current_hit = [@target, @unit, :death]
      @level.units.delete(@target)
    else
      @current_hit = [@unit, @target, :death]
      @level.units.delete(@unit)
    end
    :done
  end

  def done
    a,b = @unit, @target
    a,b = b,a if @target.team == PLAYER_TEAM
    gain_exp(a, b)
    @unit.action_available = false
    @finished = true
    @finished_animating = false
  end

end
