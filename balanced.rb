def is_balanced(opener, closer, str)
  cnt = 0
  adds = {opener => 1, closer => -1}
  pars = str.chars.select{|c| [opener, closer].include? c }
  pars.each{ |c| cnt += adds[c]; return false if cnt < 0 }
  cnt == 0
end

def is_balanced2(str)
  [['(', ')'], ['[', ']'], ['{', '}']].map{ |ps| is_balanced(*ps, str) }.all?
end

puts File.readlines('nli_parenthesis.txt').select{ |l| !is_balanced2(l.split(": ")[1]) }
