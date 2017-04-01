require_relative 'populate_geonames.rb'
include Geonames

# This script tries to find inconsistesies between roman an hebrew forms.

nli_bhb_recs = File.readlines("nli_bhb.tsv").map{ |r| r.chomp.split("\t") }
pri_rom_matches = File.readlines("pri_rom_matches.tsv")[1..-1].map{ |l| l.chomp.split("\t") }
pri_rom_matches_hash = {}
pri_rom_matches.each{ |r| pri_rom_matches_hash[r[2]] = r }

# For each row in nli_bhb.tsv:
#  PRM := search for the pri_rom_short in pri_rom_matches.tsv
#  if PRM was found:
#    append <pri_rom_matches_geonameid, pri_rom_matches_country, pri_rom_matches_feature_class, pri_rom_matches_feature_code>
#  SHM := query the sec_heb ("name_in_text") in geonames (where feature_class is 'P')
#  for each result:
#       duplicate the row and append <sec_heb_geonameid, sec_heb_primary_name, sec_heb_coordinates, sec_heb_country, sec_heb_feature_class, sec_heb_feature_code>
#       if PRM  was found:
#         if sec_heb_geonameid == pri_rom_matches_geonameid
#           set 'heb_rom_sync' to 'same'
#           remove all SHM rows with 'heb_rom_sync' ==  'missing'
#           stop traversing SHM
res = []
nli_bhb_recs.each do |nbr|
  pri_rom_nbr = nbr[2]
  prm = pri_rom_matches_hash[pri_rom_nbr]
  if prm
    # append pri_rom_matches_{lat,name,long,country,geonameid,ft_class,ft_code}
    nbr += prm[1..7]
  else
    nbr += [nil, nil, nil, nil, nil, nil, nil]
  end
  sec_heb_nbr = nbr[5]
  shm = Geonames.query_name sec_heb_nbr
  if shm.empty?
    nbr += [nil, nil, nil, nil, nil, nil, nil]
    nbr <<
      if prm
        'missing_sec_heb'
      else
        'missing_both'
      end
    res << nbr
  else
    if prm
      # TODO: traverse only once
      shm_geonames_ids = shm.map{ |geo| geo['geonameid'] }
      prm_geonameid = prm[4]
      ind = shm_geonames_ids.find_index(prm_geonameid)
      if ind
        # append sec_heb_{geonameid,name,long,lat,ft_class,ft_code,country}
        nbr += shm[ind]
        nbr << 'same'
        res << nbr
      else
        # no SHM result matches
        shm.each do |geo|
          nbr_dup = nbr + geo.values
          nbr_dup << 'different'
          res << nbr_dup
        end
      end
    else
      # shm, but no prm
      shm.each do |geo|
        nbr_dup = nbr + geo.values
        nbr_dup << 'missing_pri_rom'
        res << nbr_dup
      end
    end
  end
end

header = [
 "primary heb",
 "primary heb full",
 "primary rom",
 "primary rom full",
 "attested",
 "name in text",
 "name in text type",
 "language",
 "attestation start",
 "attestation end",
 "attestation chronology",
 "attestation chronology original",
 "attestation chronology uncertain",
 "attestation chronology approximate",
 "source",
 "original id",
 "attestation uri",

 "pri_rom_matches_lat",
 "pri_rom_matches_name",
 "pri_rom_matches_long",
 "pri_rom_matches_country",
 "pri_rom_matches_geonameid",
 "pri_rom_matches_feature_class",
 "pri_rom_matches_feature_code",

 "sec_heb_geonameid",
 "sec_heb_name",
 "sec_heb_long",
 "sec_heb_lat",
 "sec_heb_feature_class",
 "sec_heb_feature_code",
 "sec_heb_country",
]

puts header.join("\t")
res.each{ |r| puts r.join("\t") }
