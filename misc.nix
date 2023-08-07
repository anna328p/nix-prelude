{ ... }:

let
    inherit (builtins)
        toString
        ;
in {
    exports = self: { inherit (self)
        fontCss
        ;
    };

    # FontOpt : { name : Str; size : Num }
    # fontCss : FontOpt -> Str
    fontCss = opt: let
        inherit (opt) size name;
    in "${toString size}pt ${name}";
}