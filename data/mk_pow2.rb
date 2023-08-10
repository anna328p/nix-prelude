#!/usr/bin/env ruby
# frozen_string_literal: true

CEILING = 63

puts "i: assert i >= 0; assert i <= #{CEILING};"
puts 'builtins.elemAt ['

def print_row(val, desc)
  max_len = (2**CEILING + 1).to_s.length

  col = val.to_s.ljust(max_len)
  puts "    #{col} # #{desc}"
end

(0...CEILING).each do |i|
  print_row(2**i, "2**#{i}")
end

puts "    (2 * #{2**(CEILING - 1)}) # 2**#{CEILING}"

puts '] i'
