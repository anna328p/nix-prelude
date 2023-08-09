{ self, ... }:

let
    inherit (builtins)
		isFunction
        isAttrs attrNames attrValues mapAttrs
        length filter foldl' map genList elemAt concatLists
        listToAttrs concatStringsSep
        isString
        zipAttrsWith
        ;

in with self; rec {
    exports = self: { inherit (self)
        isSet

        mkMapping
        optionalAttr optionalsAttr

        mergeSets
        flattenSetSep
        mapAttrValues
        flatMapSetRec

        mapSetPairs
        mapSetEntries
        setPairs

        genSet
        ;
    };

    isSet = isAttrs;

    # optionalAttr : Str -> Set a -> [a]
    optionalAttr = attr: set:
        if set ? ${attr}
            then [ set.${attr} ]
            else [];

    # optionalsAttr : Str -> Set a -> (a | List)
    optionalsAttr = attr: set: set.${attr} or [];
    
    # mergeSets : [Set Any] -> Set Any
    mergeSets = foldl' (l: r: l // r) {};

    diffSets = a: b: let
        optionalValues = a: b: k: let
            get = set: key: if set ? ${key} then { ${key} = set.${key}; } else {};
        in
            { a = get a n; b = get b n; };

        diffNames = a: b: let
            c = a // b;
            pred = k: (a ? ${k}) -> (b ? ${k}) -> (a.${k} != b.${k});
        in
            filter pred (attrNames c);

        in zipAttrsWith (_: mergeSets) (map (optionalValues a b) (diffNames a b));
    
    # flatMapSetRec = Dict Any -> ([String] -> Any -> Any) -> [Any]
    flatMapSetRec = let
    	recurse = path: fn: set: let
    		keys = attrNames set;
    		values = attrValues set;
    		size = length keys;

    		mapFn = key: val:
    			if isAttrs val then
    				recurse (path ++ [key]) fn val
    			else
    				singleton (fn path key val);

    		indexFn = i: mapFn (elemAt keys i) (elemAt values i);
    	in
    		assert isFunction fn;
    		assert isAttrs set;
    		concatLists (genList indexFn size);
    in
    	recurse [];

    # flattenSetSep : Str -> Set Any -> Set (Except Set)
    flattenSetSep = sep: let
        mkPair = path: key: mkMapping
        	(concatStringsSep sep (path ++ [key]));

        toList = flatMapSetRec mkPair;
    in
    	o listToAttrs toList;
    
    # mapAttrValues =
    #     sig forall (a: b: (Fn a _- b) _- Set a _- Set b)

    # mapAttrValues : (a -> b) -> Set a -> Set b
    mapAttrValues = o mapAttrs const;

    # mapSetPairs : Set -> ((String, Any) -> a) -> [a]
    mapSetPairs = f: set: let
        keys = attrNames set;
        values = attrValues set;
        count = length keys;
    in
        genList (o f (pairAt keys values)) count;

    # mapSetEntries : Set -> (String -> Any -> a) -> [a]
    mapSetEntries = f: set: let
        keys = attrNames set;
        values = attrValues set;
        count = length keys;
    in
        genList (i: f (elemAt keys i) (elemAt values i)) count;

    # setPairs : Set -> [ (String, Any) ]
    setPairs = mapSetPairs id;

    # mkMapping : String -> a -> Record { name : String, value : a }
    mkMapping = name: value:
        assert isString name;
        { inherit name value; };

    # genSet = [String] -> (String -> a) -> Dict a
    genSet = fn: let
        toPairs = map (k: mkMapping k (fn k));
    in
        o listToAttrs toPairs;
}
