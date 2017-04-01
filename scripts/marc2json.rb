require 'marc'
require 'yaml'
require 'json/ext'

def process_rec rec, field2desc
  res_rec = {}
  rec.fields.each do |field|
    desc = field2desc[field.tag]
    if desc
      res_rec[desc] ||= []
      if field.respond_to? :subfields
        subfields = {}
        field.subfields.each do |sub|
          subfields[sub.code] = sub.value
        end
        res_rec[desc] << subfields
      else
        res_rec[desc] << field.value
      end
    end
  end

  res_rec
end

if ARGV.size != 2
  puts "usage: marc2json <MARC XML file> <fields YAML file>"
  exit
end

field2desc = YAML.load_file ARGV[1]
res = []
reader = MARC::XMLReader.new(ARGV[0], :external_encoding => "MARC-8")
begin
  reader.each do |rec|
    res_rec = process_rec rec, field2desc
    # skip fields with just one field (the id)
    res << res_rec if res_rec && res_rec.keys.size > 1
  end
rescue => e
  STDERR.puts e
  STDERR.puts e.backtrace
end
puts res.to_json
