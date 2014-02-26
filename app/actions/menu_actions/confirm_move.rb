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
    unit.skills.select(&:action?).each do |skill|
      if valid_targets(skill.target, skill.range).any?
        opts << skill.identifier
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
    map_action = @level.map(@unit.x, @unit.y).actions[sym]
    if map_action
      return map_action.new(@unit, @level, @level.map(@unit.x, @unit.y), self)
    end
    skill = @unit.skills.find{|s| s.identifier == sym.to_s }
    if skill
      TargetSelect.new(@unit, @level, valid_targets(skill.target, skill.range), @path, skill.effect, self) do |t|
        # SkillActivator.new(skill, @unit, t, @level)
        skill.activate!(@unit, t, @level)
        @unit.action_available = false
        @level.next_action(@unit.x, @unit.y)
      end
    else
      super(sym, *args)
    end
  end
end
