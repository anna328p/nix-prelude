{ L, parsec, ... }:

let
    inherit (builtins)
        toXML
        isFunction
        foldl'
        ;

    parsec-xml = import ./contrib/parse-xml.nix {
        nix-parsec = parsec;
        inherit L;
    };

    inherit (parsec-xml) parseXml;

in with L; rec {
    exports = self: { inherit (self) 
        hasEllipsis
        hasFormals
        lambdaArgName
        ;
    };

    findChild = obj: name: find (v: (v.name or null) == name) obj.children;

    describe = o parseXml toXML;

    dig = foldl' findChild;

    # Return values:
    # true  : function with set pattern, with ellipsis
    # false : function with set pattern, without ellipsis
    # null  : function without set pattern

    # hasEllipsis : (a -> b) -> (Bool | Null)
    hasEllipsis = f: let
        parseRes = describe f;
        attrspat = dig parseRes.value [ "expr" "function" "attrspat" ];
    in
        assert isFunction f;

        if attrspat == null then
            null
        else
            (attrspat.attributes.ellipsis or null) == "1";

    hasFormals = f: let
        parseRes = describe f;
        attrspat = dig parseRes.value [ "expr" "function" "attrspat" ];
    in
        assert isFunction f;
        attrspat != null;

    lambdaArgName = f: let
        parseRes = describe f;
        varpat = dig parseRes.value [ "expr" "function" "varpat" ];
    in
        assert isFunction f;

        if varpat == null then
            null
        else
            (varpat.attributes.name or "");
}