class Staff
end

class HealingStaff < Staff
  def pretty
    "healing staff"
  end
  def activate!(me, target, level)
    target.heal(me.magic + 10)
  end
  def used_up?
    false
  end
  def valid_target?(t)
    true
  end
end

Item.register('healing' => HealingStaff)

# Planned Staves / Wands
=begin
  Warp
  Rescue
  Rewarp (self tele)
  Retreat (remove a unit from battle for this level)
  Recover (heal status)
  Heal
    standard
    + value
    + all valid targets
    ^ all the above, at range, as well.
  Torch
  Unlock
  Status Buffs
---------
  Repel (enemy unit)
  Summon (Enemy unit)
  Stasis/Rift (enemy unit can't move or do anything for a few turns)
    - Stasis leaves a blocker in their space, rift does not)
  Inflict (gives them a status effect, like poison, etc)
  Shade (enemy only?)
  Lock (perminantly blocks off a door.)
  Status debuffs (str, magic, mag def, def, speed)
=end
