#!/usr/bin/env ruby

Encoding.default_external = 'ASCII-8BIT'
Encoding.default_internal = 'ASCII-8BIT'

str = (0..255).map { |i| %Q(\t"#{i.chr}" = #{i};) }.join("\n").then { "{\n#{_1}\n}" }

# escapes
str.sub! %Q("\t"), %q("\t")
str.sub! %Q("\n"), %q("\n")
str.sub! %Q("\r"), %q("\r")
str.sub! %q("\"),  %q("\\\\\")
str.sub! %q("""),  %q("\"")

File.write 'ascii-table.nix', str
