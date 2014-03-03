require './gosu'



describe PlayerUnit do
  trees = PlayerUnit.basic_classes.map{|x| [x]}
  puts "Basic classes are #{trees}"
  size = 0
  while size != trees.size
    size = trees.size
    new_trees = []
    trees.each do |t|
      puts "current class is #{t.last}"
      if PlayerUnit.config[t.last]['promotes']
        PlayerUnit.config[t.last]['promotes'].each do |p|
          new_trees << t + [p]
        end
      else
        new_trees << t
      end
    end
    trees = new_trees
  end
  trees.each do |t|
    it "#{t.inspect} is a valid promotion path" do
      base = t.shift
      pl = PlayerUnit.new(base, "test", 1)
      t.each do |p|
        pl.promote(p)
      end
    end
  end
end
