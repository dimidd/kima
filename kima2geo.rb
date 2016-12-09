require 'set'
require 'json'
require 'safe-enum'


class Field < Enum::Base
  values :PriHeb,
     :PriHebFull,
     :PriRom,
     :PriRomFull,
     :Attested,
     :Name,
     :NameType,
     :Lang,
     :AtsStart,
     :AtsEnd,
     :AtsChron,
     :AtsChronOrig,
     :AtsChronUncert,
     :AtsChronApprox,
     :Src,
     :OrigId
end

def f2i n; Field.index n; end

lines = File.readlines "kima_sample2.tsv"
lines2 = lines.map{ |l| l.chomp.split("\t") }
headers = lines2[0]
rows = lines2[1..-1]

rows2 = rows.map do |line|
  line.map do |field|
    normal = field
    normal = field[1..-2] if field[0] == field[-1] && field[-1] == '"'
    normal = normal[0..-2] if normal[-1] == ','
    normal
  end
end

res = []
# how to group the top level
key1 = f2i :PriHeb
grp = rows2.group_by{ |row| row[key1] }
top_id = 0
grp.each do |k, v|
  rec = {
    "type" => "Feature",
    "id" => top_id,
    "uri" => "http://www.kima.org/place/#{top_id}",
    "title" => "#{v[0][f2i :PriHebFull]} | #{v[0][f2i :PriRomFull]}",
    "bbox" => "31.771959, 35.217018, 31.771959, 35.217018",
    "when" => {"start" => 12345, "end" => 12345 },
    "links" => {
        "close_matches" => ['http://www.geonames.org/1234567'],
        "exact_matches" => ['https://pleiades.stoa.org/places/1234567']
    },
    "primary_form" => v[0][f2i :PriHebFull],
    "primary_form_romanized" => v[0][f2i :PriRomFull],
    "names" => []
  }

  names = Set.new
  name_id = 0
  top_start = 9999
  top_end = -9999
  dates = {}

  # how to group the second level
  key2 = f2i :Attested
  ats_id = 0
  v.each do |ats|
    if names.add?(ats[key2])
      name_rec =
        {
          "name_id" => name_id,
          "attested" => ats[key2],
          "language" => ats[f2i :Lang],
          "attested_in" => []
        }
      rec["names"] << name_rec
      name_id += 1
      ats_start = ats[f2i :AtsStart].to_i
      ats_end = ats[f2i :AtsEnd].to_i
      top_start = [top_start, ats_start].compact.min
      top_end =   [top_end,   ats_end].compact.max
      dates[ats[key2]] =
        {
          start: ats_start,
          end: ats_end,
          name_ind: names.size - 1
        }
    else
      dates[ats[key2]][:start] =  [dates[ats[key2]][:start],  ats_start].compact.min
      dates[ats[key2]][:end] =    [dates[ats[key2]][:end],    ats_end  ].compact.max
    end

    ats_rec = {}
    ats_rec["attestation_id"] = ats_id
    ats_rec["name_in_text"] = ats[f2i :Name]
    ats_rec["name_in_text_type"] = ats[f2i :NameType]
    ats_rec["when"] = {"attestation_start" => ats_start, "attestation_end" => ats_end}
    ats_rec["attestation_chronology"] = ats[f2i :AtsChron]
    ats_rec["attestation_chronology_original"] = ats[f2i :AtsChronOrig]
    ats_rec["attestation_chronology_uncertain"] = ats[f2i :AtsChronUncert]
    ats_rec["attestation_chronology_approximate"] = ats[f2i :AtsChronApprox]
    ats_rec["attestation_uri"] = "example.com/12345"
    ats_rec["original_id"] = ats[f2i :OrigId]
    rec["names"].last["attested_in"] << ats_rec
    ats_id += 1
  end

  dates.each do |k, v|
    rec["names"][v[:name_ind]]["when"] =
      {
        "start" => v[:start],
        "end" => v[:end]
      }
  end

  rec["when"]["start"] = top_start
  rec["when"]["end"] = top_end
  res << rec
  top_id += 1
end

puts res.to_json
