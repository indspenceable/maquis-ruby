class ConfirmMove < MenuAction
  attr_reader :level

  attr_accessor :can_undo_move

  def initialize(unit, path, level, &prev_action)
    @level = level
    @unit = unit
    @prev_action = prev_action
    @path = path
    opts = []
    if valid_targets(:foes, unit.accessible_range).any?
      opts << :attack
    end
    unit.skills.map(&:actions).each do |al|
      al.each do |n, target_type, callback, _|
        if targets(target_type, callback).any?
          opts << n
        end
      end
    end
    if valid_targets(:friends, 1).any?
      opts << :trade
    end
    level.map(unit.x, unit.y).actions.each do |name, val|
      opts << name
    end
    opts << :items
    opts << :confirm
    super(opts)
  end

  def targets(target_type, callback)
    case target_type
    when :units
      @level.units.select{|u| callback.call(@unit, u, @level) }
    else
      raise "Skill has invalid target #{target_type}"
    end
  end

  def units_for_info_panel
    [@unit]
  end

  def valid_targets(type, range)
    range = (range..range) unless range.respond_to?(:include?)

    return case type
    when :friends
      # find friends, in range
      # assume we can see them.
      @level.units.select do |u|
        (u.team == @unit.team) && range.include?(Path.unit_dist(u, @unit))
      end
    when :foes
      #find enemies, that we can see, in range
      @level.units.select do |u|
        u.team != @unit.team &&
        @level.see?(u.x, u.y) &&
        range.include?(Path.unit_dist(u, @unit))
      end
    end
  end

  def enemies_in_range
    @enemies_in_range ||= @level.units.select do |u|
      u.team != @unit.team &&
      @level.see?(u.x, u.y) &&
      @unit.available_weapons.any?{|w| w.in_range?(Path.unit_dist(@unit, u))}
    end
  end

  def friends_adjacent
    @friends_adjacent ||= @level.units.select do |u|
      (u.team == @unit.team) && (Path.unit_dist(u, @unit) == 1)
    end
  end

  def attack
    AttackTargetSelect.new(@unit, @level, enemies_in_range, @path, self)
  end

  def draw(window)
    draw_map(window)
    draw_all_units(window)
    # window.draw_path(@path)
    window.draw_menu(@choices, @index)
  end

  def confirm
    @unit.action_available = false
    @level.next_action(@unit.x, @unit.y)
  end

  def cancel
    @prev_action.call
  end

  def trade
    TradeTargetSelect.new(@unit, @level, friends_adjacent, @path, self)
  end

  def items
    Inventory.new(@unit, @level) { self }
  end

  def method_missing(sym, *args)
    # require 'pry'
    # binding.pry
    # heh, not used yet.
    map_action = @level.map(@unit.x, @unit.y).actions[sym]
    if map_action
      return map_action.new(@unit, @level, @level.map(@unit.x, @unit.y), self)
    end
    action_name = sym.to_s
    skill = @unit.skills.find{|s| s.action?(action_name) }
    if skill
      name, target_type, target_callback, action = skill.action!(action_name)
      TargetSelect.new(@unit, @level, targets(target_type, target_callback), @path, skill.effect, self) do |t|
        action.call(@unit, t, @level)
      end
    else
      super(sym, *args)
    end
  end
end
