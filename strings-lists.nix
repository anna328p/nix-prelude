{ self, ... }:

with self; let
    inherit (builtins)
        isInt
        isList length elemAt genList
        head tail
        isString stringLength substring split
        getAttr
        foldl' concatLists filter
        concatStringsSep
        all
		match
        ;
in rec {
    exports = self: { inherit (self)
        sublist
        repeatStr
        fixedWidthString
        init last

        replicate

        leftPadListObj rightPadListObj
        leftPadListList rightPadListList
        leftPadStr rightPadStr

        sliceListN sliceStrN
        spansOf
        mapCons
        mapConsPairs mapConsPairs'

        addStrings
        concatStrings
        concatMapStringsSep concatMapStrings
        concatLines concatMapLines

        stringToChars
        imapStringChars mapStringChars

        charToInt

        findIndex find
        filterIndices
        splitOn

        match'

        lines

        replaceAt

        optionals optional
        none
        flatten
        compact

        length' lengthsEq

        foldl1
        sum
        product
        average
        ;
    };

    # addLists : [a] -> [a] -> [a]
    addLists = a: b: a ++ b;

    # addStrings : String -> String -> String
    addStrings = a: b: a + b;

    # sublist : Int -> Int -> [a] -> [a]
    sublist = start: count: list: let
        len = length list;

        trueCount =
        	if (start + count) < len then
        		count
            else if start >= len then
            	0
            else
            	(len - start);
    in
        assert isPositiveInt start;
        assert isPositiveInt count;
        assert isList list;
        
        genList (i: elemAt list (i + start)) trueCount;

    charAt = str: index: let
        len = stringLength str;
    in
        assert isString str;
        assert isPositiveInt index;
        assert index < len;
        substring index 1 str;

    # repeatStr : Str -> Int -> Str
    repeatStr = str: count: concatStrings (replicate count str);

    # repeatStr : [a] -> Int -> [a]
    repeatList = list: count: concatLists (replicate count list);

    # init : [a] -> [a]
    init = list: let
        len = length list;
    in
        assert isList list;
        if len < 2 then
            []
        else
            genList (elemAt list) (len - 1);
    
    # last : [a] -> a
    last = list: let
        len = length list;
    in
        assert isList list;
        if (len == 0) then
            null
        else
            elemAt list (len - 1);

    # getLenFn = T a -> Int
    # mkRepeatFn = a -> Int -> T a
    # getSliceFn = T a -> Int -> Int -> T a
    # rtlFn = T a -> Int -> T a

    # rtlArg = Set (getLenFn | mkRepeatFn | getSliceFn)
    # repeatToLen' : rtlArg -> rtlFn
    repeatToLen' = { getLen, mkRepeat, getSlice }:
        filler: width: let
            fLen = getLen filler;
            nRep = ceilDiv fLen width;

            repeats = mkRepeat filler nRep;
        in
            if width == fLen * nRep
                then repeats
                else getSlice 0 width repeats;
    
    # repeatStrToLen : Str -> Int -> Str
    repeatStrToLen = repeatToLen' {
        getLen = stringLength;
        mkRepeat = repeatStr;
        getSlice = substring;
    };

    # repeatListToLen : [a] -> Int -> [a]
    repeatListToLen = repeatToLen' {
        getLen = length;
        mkRepeat = repeatList;
        getSlice = sublist;
    };

    # fixedWidthString : Int -> Str -> Str -> Str
    fixedWidthString = width: filler: str: let
        sLen = stringLength str;
        fLen = stringLength filler;

        nEmptySpaces = width - sLen;
        padding = repeatStrToLen filler nEmptySpaces;
    in
        assert isInt width;
        assert isString filler;
        assert fLen > 0;
        assert sLen < width;

        if nEmptySpaces == 0
            then str
            else padding + str;
    
	# replicate : Int -> a -> [a]
	replicate = n: x: genList (const x) n;

    # predFn = Any -> Bool
    # getLenFn = T a -> Int
    # mkPadFn = a -> Int -> T a
    # joinFn = T a -> T a -> T a
    # padFn = a -> Int -> T a -> T a
    
    # genericPadArg : Set (predFn | getLenFn | mkPadFn | joinFn)

    # genericPad : predFn -> predFn -> getLenFn -> mkPadFn -> joinFn -> padFn
    genericPad = { isInnerType, isContainer, getLen, mkPad, join }:
        filler: width: input: let
            inputLen = getLen input;
            padding = mkPad filler width;
        in
            assert isInnerType filler;
            assert isInt width;
            assert isContainer input;

            if inputLen >= width
                then input
                else join input padding;

    padListObj' = join: genericPad {
        isInnerType = const true;
        isContainer = isList;
        getLen = length;
        mkPad = flip replicate;
        inherit join;
    };

    # leftPadListObj : a -> Int -> [a] -> [a]
    leftPadListObj = padListObj' (flip addLists);

    # rightPadListObj : a -> Int -> [a] -> [a]
    rightPadListObj = padListObj' addLists;

    padListList' = join: genericPad {
        isInnerType = isList;
        isContainer = isList;
        getLen = length;
        mkPad = repeatListToLen;
        inherit join;
    };

    # leftPadListList : [a] -> Int -> [a] -> [a]
    leftPadListList = padListList' (flip addLists);

    # rightPadListList : [a] -> Int -> [a] -> [a]
    rightPadListList = padListList' addLists;

    padStr' = join: genericPad {
        isInnerType = isString;
        isContainer = isString;
        getLen = stringLength;
        mkPad = repeatStrToLen;
        inherit join;
    };

    # leftPadStr : Str -> Int -> Str -> Str
    leftPadStr = padStr' (flip addStrings);

    # rightPadStr : Str -> Int -> Str -> Str
    rightPadStr = padStr' addStrings;

    genericSliceN = { getLen, getSlice }:
        width: input: let
            inputLen = getLen input;
            nSlices = ceilDiv inputLen width;
            mkSlice = ix: getSlice (ix * width) width input;
        in
            genList mkSlice nSlices;
    
    # sliceListN : Int -> [a] -> [[a]]
    sliceListN = genericSliceN {
        getLen = length;
        getSlice = sublist;
    };

    # sliceStrN : Int -> Str -> [Str]
    sliceStrN = genericSliceN {
        getLen = stringLength;
        getSlice = substring;
    };

    # mapCons : Int w -> (Tuple w a -> b) -> [a] -> [b]
    mapCons = width: fn: list: let
		len = length list;
		mkSpan = start: genList (i: elemAt list (start + i)) width;
	in
		assert isNat width;
		assert isList list;
		assert len >= width;

		genList (o fn mkSpan) (len - width + 1);

	# spansOf
	#
	# spansOf 2 [ 1 2 3 4 ] => [ [ 1 2 ] [ 2 3 ] [ 3 4 ] ]
	# spansOf 3 [ 1 2 3 4 ] => [ [ 1 2 3 ] [ 2 3 4 ] ]

	# spansOf : Int -> [a] -> [[a]]
	spansOf = flip mapCons id;

    # mapConsPairs : ((a, a) -> b) -> [a] -> [b]
    mapConsPairs = mapCons 2;

    # mapConsPairs' : (a -> a -> b) -> [a] -> [b]
    mapConsPairs' = o mapConsPairs uncurry;

    concatStrings = concatStringsSep "";

    # concatMapStringsSep : Str -> (Str -> Str) -> [Str] -> Str
    concatMapStringsSep = sep: fn: list:
        concatStringsSep sep (map fn list);
    
    concatMapStrings = concatMapStringsSep "";

    # concatLines : [Str] -> Str
    concatLines = concatStringsSep "\n";

    # concatMapLines : (a -> Str) -> [a] -> Str;
    concatMapLines = concatMapStringsSep "\n";

    # stringToChars : Str -> [Str]
    stringToChars = input:
        assert isString input;
        genList (charAt input) (stringLength input);

    # imapStringChars : (Int -> Str -> a) -> Str -> [a]
    imapStringChars = fn: input: let
        mapFn = i: fn i (charAt input i);
    in
        assert isString input;
        genList mapFn (stringLength input);

    # mapStringChars : (Str -> a) -> Str -> [a]
    mapStringChars = o imapStringChars const;
    
    # asciiTable : Dict Int
    asciiTable = import data/ascii-table.nix;

    # isChar : Str -> Bool
    isChar = c: isString c && (stringLength c) == 1;

    # charToInt : Char -> Int
    charToInt = flip getAttr asciiTable;

    # note: strictly O(n), iterates the entire list every time.
    # working on a new approach that can short-circuit early;
    # lack of tail recursion makes it hard.

    # findIndex : (a -> Bool) -> [a] -> (Int | Null)
    findIndex = pred: list: let
        iteration = acc: val:
            if acc >= 0 then
                acc
            else if pred val then
                -acc - 1
            else
                acc - 1;

        res = foldl' iteration (-1) list;
    in
        if res >= 0 then res else null;

    # find : (a -> Bool) -> [a] -> (a | Null)
    find = pred: list: let
        ix = findIndex pred list;
    in
        if ix != null
            then elemAt list ix
            else null;


    # filterIndices : (a -> Bool) -> [a] -> [Nat]
    filterIndices = pred: list: let
    	optionalIndex = ix:
    		if pred (elemAt list ix)
    			then ix
    			else null;

    	ixs = genList optionalIndex (length list);
    in
    	assert isLambda pred;
    	assert isList list;

    	filter isInt ixs;

	# splitOn
	#
	# Divides a list into a list of lists, "cutting" where a predicate matches.
	# The delimiting elements are dropped.
	# Examples:
	# splitOn isNull [ 1 2 3 null 4 5 ] => [ [ 1 2 3 ] [ 4 5 ] ]
	# splitOn isNull [ null 1 null null 2 null ] => [ [] [ 1 ] [] [ 2 ] [] ]

    # splitOn : (a -> Bool) -> [a] -> [[a]]
    splitOn = pred: list: let
    	len = length list;

    	ixs = filterIndices pred list;
    	ixs' = concatLists [ [ (-1) ] ixs [ len ] ];

		getSlice = left: right:
			genList
				(i: elemAt list (left + i + 1))
				(right - left - 1);

    	spans = mapConsPairs' getSlice ixs';
    in
    	assert isLambda pred;
    	assert isList list;

		if len == 0
			then list
			else spans;

	# match' : Str -> Str -> Bool
	match' = re: str: (match re str) != null;

	# lines : Str -> [Str]
	lines = str:
		assert isString str;
		filter isString (split "[\r\n]+" str);

	# replaceAt : [a] -> Nat -> a -> [a]
	replaceAt = xs: index: val: let
		len = length xs;

		fn = i: if i == index
			then val
			else elemAt xs i;
	in
		assert isList xs;
		assert isPositiveInt index;
		assert index < len;

		genList fn len;

    # optionals : Bool -> [a] -> [a];
    optionals = testRes: arg:
        if testRes then arg else [];

    # optionals : Bool -> a -> [a];
    optional = testRes: arg: optionals testRes [ arg ];

	# none : (a -> Bool) -> [a] -> Bool
	none = f: all (x: !(f x));

    # NestedList : Type -> Type
    # NestedList a = [a | NestedList a]

    # flatten : NestedList a -> [a]
    flatten = list: let
        fn = v: if isList v then flatten v else [v];
    in
        assert isList list;

        if none isList list
            then list
            else concatLists (map fn list);


	# compact : [a | Null] -> [a]
	compact = filter (x: x != null);


	# length' : [Any] | String -> Int
	length' = val:
		assert (isList val) || (isString val);

		if isList val then
			length val
		else if isString val then
			stringLength val
		else
			unreachable;


	# lengthsEq = [Any] | String -> [Any] | String -> Bool
	lengthsEq = a: b: (length' a) == (length' b);


    # foldl1 : (b -> a -> b) -> [a] -> b
    foldl1 = fn: list:
    	assert isLambda fn;
    	assert isList list;
    	assert (length list) >= 1;
    	foldl' fn (head list) (tail list);


    # sum : [Int] -> Int
    sum = foldl' __add 0;


    # product : [Int] -> Int
    product = foldl' __mul 1;


	# average : [Int, Float] -> Float
	average = list: let
		len = length list;
	in
		assert (isList list) && len > 0;
		(sum list) / len;
}
