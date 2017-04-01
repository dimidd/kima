require 'marc'
require 'yaml'
require 'json/ext'

res = []
reader = MARC::XMLReader.new(ARGV[0])

begin
  reader.each_with_index do |rec, i|
      res << rec if i % 400 == 0
  end
rescue => e
  STDERR.puts e
  STDERR.puts e.backtrace
end

writer = MARC::XMLWriter.new(ARGV[0] + '.sample')
res.each do |rec|
	writer.write(rec)
end
writer.close()
