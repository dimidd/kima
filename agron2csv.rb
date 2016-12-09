require 'json'

lines = File.readlines "agron_tmp3"
puts "id, pri.a, pri.9, pri.x, pri.y, pri.v, pri.z, sec.a, sec.9, sec.x, sec.y, sec.w, sec.7, sec.v, sec.z, sec.b"
recs = []
first = true
cur = nil
id = nil
pris = secs = nil

lines.each do |l|
	l2 = l.chomp
	key, val = l2.split ': '
	case key
	when 'id'
		recs << [id, pris, secs] unless first
		pris = {}
		secs = {}
		id = val
		first = false
	when 'pri'
		cur = pris
	when 'sec'
		cur = secs
	else
		cur[key] = val
	end
end
recs2 = recs.map do |r|
	[
		r[0],
		r[1]['a'],
		r[1]['9'],
		r[1]['x'],
		r[1]['y'],
		r[1]['v'],
		r[1]['z'],
		r[2]['a'],
		r[2]['9'],
		r[2]['x'],
		r[2]['y'],
		r[2]['w'],
		r[2]['7'],
		r[2]['v'],
		r[2]['z'],
		r[2]['b']
	].join(', ')
end
puts recs2
