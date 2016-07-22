require "pp"

dir = File.dirname(__FILE__)
files = Dir.glob(dir + "/*.rb").reject { |path| File.basename(path) =~ /^v1_/ }
files.each do |file|
  contents = File.read(file)
  dir = File.dirname(file)
  basename = File.basename(file)
  File.write(File.join(dir, "v1_" + basename), contents)
end
