require 'marc'
require 'yaml'
require 'json/ext'

if ARGV.size != 2
  puts "usage: marc2json <MARC XML file> <fields YAML file>"
  exit
end

field2desc = YAML.load_file ARGV[1]
res = []
reader = MARC::XMLReader.new(ARGV[0])
begin
  reader.each do |rec|
    res_rec = {}
      rec.fields.each do |field|
        desc = field2desc[field.tag]
        if desc
          res_rec[desc] = {}
          if field.respond_to? :subfields
            res_rec[desc]['subfields'] = {}
            field.subfields.each do |sub|
              res_rec[desc]['subfields'][sub.code] = sub.value
            end
          else
            res_rec[desc] = field.value
          end
        end
      end
      res << res_rec
  end
rescue => e
  STDERR.puts e
  STDERR.puts e.backtrace
end
final = {}
final['records'] = res
puts final.to_json
