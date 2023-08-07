{ ... }:

{
    exports = self: { inherit (self) urlencode; };

    urlencode = builtins.replaceStrings
      [ "!"   "#"   "$"   "&"   "'"   "("   ")"   "*"
        "+"   ","   ":"   ";"   "="   "?"   "@"   "["
        "]"   " "   "%"   "."   "<"   ">"   "\\"  "^"
        "`"   "{"   "|"   "}"   "~"   ]

      [ "%21" "%23" "%24" "%26" "%27" "%28" "%29" "%2A"
        "%2B" "%2C" "%3A" "%3B" "%3D" "%3F" "%40" "%5B"
        "%5D" "%20" "%25" "%2E" "%3C" "%3E" "%5C" "%5E"
        "%60" "%7B" "%7C" "%7D" "%7E" ];
}