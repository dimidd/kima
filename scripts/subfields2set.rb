require 'set'

lines = File.readlines "agron_subfields4.txt"
prims = Set.new
secs = Set.new
cur = prims

lines.each do |l|
  l2 = l.chomp
  case l2
  when "pri"
    cur = prims
  when "sec"
    cur = secs
  else
    cur.add l2
  end
end
fields = []
[[prims, "pri"], [secs, "sec"]].each do |set, name|
  fields << set.map{ |f| "#{name}.#{f}" }.join(', ')
end
puts fields.join(', ')
