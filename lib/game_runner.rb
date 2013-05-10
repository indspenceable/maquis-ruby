module GameRunner
  def setup
    klasses = [ArmorKnight, Archer, Cavalier, Myrmidon, Mercenary, PegasusKnight, Fighter].shuffle
    l = 3
    pl = 3.times.map do |x|
      kl = klasses.shuffle.pop
      u = kl.new(PLAYER_TEAM, Names.generate, 0, 0, l+2, x==0)
      l -= 1 if l > 1
      u
    end
    level = Level.generate(pl, 1)
    @x, @y = 1, 1
    @current_action = MapSelect.new(3, 3, level)
  end

  def display(screen)
    display_map(screen)
    display_character_info(screen)
    display_messages(screen)

    @current_action.draw(screen)
    # screen.map.set_xy(@x,@y)
    finish_display
  end

  def execute
    @current_action = @current_action.execute if @current_action.respond_to?(:execute)
  end

  def move_to_correct_space(screen)
    @current_action.set_cursor(screen)
  end
end
