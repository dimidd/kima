require 'pg'
require 'iso_country_codes'

module Geonames
  # HT: http://notetoself.vrensk.com/2008/08/escaping-single-quotes-in-ruby-harder-than-expected/comment-page-1/
  def quote(str)
    str.gsub(/\\|'/){ |c| "\\#{c}" }
  end

  def wrap(str)
    "E'" + quote(str) + "'"
  end

  DB = PG.connect dbname: 'geonames', user: 'kima'

  def create_db
    names_query = <<-eos
    create table if not exists names (
      id bigserial primary key,
      geonameid bigint unique,
      name varchar(200),
      asciiname varchar(200),
      geo geography(point,4326),
      ft_class char(1),
      ft_code varchar(10),
      country char(2)
      );
      eos
    DB.exec names_query

    aliases_query = <<-eos
    create table if not exists aliases (
      id bigserial primary key,
      geonameid bigint references names(geonameid),
      nameid bigint references names(id),
      alias varchar(200)
      );
      eos
    DB.exec aliases_query
  end

  def drop_db
    DB.exec 'drop table names, aliases;'
  end

  def index_db
    DB.exec 'create index names_geoid on names(geonameid);'
    DB.exec 'create index names_name on names(name);'
    DB.exec 'create index aliases_alias on aliases(alias);'
  end

  def populate tsv = 'geonames/allCountries.txt'
    File.readlines(tsv).each do |line|
      spl = line.chomp.split("\t")
      geonameid, name, asciiname = spl[0], wrap(spl[1]), wrap(spl[2])
      point = "ST_MakePoint(#{spl[5]}, #{spl[4]})"
      ft_class, ft_code = wrap(spl[6]), wrap(spl[7])
      country = wrap(spl[8])
      # TODO: handle alt countries
      name_values = [geonameid, name, asciiname, point, ft_class, ft_code, country].join(', ')
      insert_names_query = <<-eos
        insert into names
          (geonameid, name, asciiname, geo, ft_class, ft_code, country)
          values (#{name_values})
          returning id;
          eos
      res = DB.exec(insert_names_query)
      name_id = res.first['id']

      aliases = spl[3].split ','
      aliases.each do |a|
        values = [geonameid, name_id, wrap(a)].join(', ')
        DB.exec "insert into aliases (geonameid, nameid, alias) values (#{values});"
      end
    end
  end

  def query_name name
    wrapped = wrap name
    query = <<-eos
      select  geonameid,
              name,
              ST_X(geo::geometry) as long,
              ST_Y(geo::geometry) as lat,
              ft_class as feature_class,
              ft_code as feature_code,
              country
      from names
      where name = #{wrapped} and ft_class = 'P' and ft_code <> 'PPLQ';
      eos
    res = DB.exec(query).to_a
    if res.empty?
      query2 = <<-eos
        select  names.geonameid,
                alias as name,
                ST_X(geo::geometry) as long,
                ST_Y(geo::geometry) as lat,
                ft_class as feature_class,
                ft_code as feature_code,
                country
        from aliases inner join names
          on aliases.nameid = names.id
        where alias = #{wrapped} and ft_class = 'P' and ft_code <> 'PPLQ';
        eos
      res = DB.exec(query2).to_a
    end

    res
  end


  def match names_file
    res = {}
    File.readlines(names_file).each do |line|
      name = line.chomp.gsub('"', '').gsub(/\(.*\)/, '').strip
      res[name] = query_name name
      res[name].each do |geo|
        geo = expand_country geo
      end
    end

    res
  end

  def expand_country geo
    country_code = geo['country']
    begin
      country_name = IsoCountryCodes.find(country_code)
    rescue => e
      country_name = nil
    end
    geo['country'] = country_name.name if country_name

    geo
  end

  # convert to Google Refine friendly format
  def refinize hash
    arr = []
    hash.keys.each{ |k| arr << {"name" => k, "geos" => hash[k]} }

    arr
  end

  def main match_path
    #drop_db
    #create_db
    #populate
    #index_db
    arr = refinize(match match_path)

    puts arr.to_json
    STDERR.puts "empty: #{arr.select{ |e| e["geos"].empty? }.size} total: #{arr.size}"
  end
end

if __FILE__ == $0
  include Geonames
  Geonames.main ARGV[0]
end
