require File.join(File.dirname(__FILE__), "app/app.rb")

SAVE_FILE_PATH = File.expand_path(File.join('~', '.tarog'))
previous_save = if File.exists?(SAVE_FILE_PATH)
  begin
    Marshal.load(File.read(SAVE_FILE_PATH))
  rescue TypeError => e
    puts "Type Error. Dropping corrupt save."
    nil
  end
end

Gosu::enable_undocumented_retrofication
previous_save = nil if ARGV.include?('w')
DISPLAY = GosuDisplay.new(previous_save)

DISPLAY.show
