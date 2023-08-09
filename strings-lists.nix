{ self, ... }:

with self; let
    inherit (builtins)
        isInt
        isList length elemAt genList
        isString stringLength substring
        getAttr
        foldl' concatLists filter
        concatStringsSep
        all
        ;
in rec {
    exports = self: { inherit (self)
        sublist
        repeatStr
        fixedWidthString
        init last

        genList'

        leftPadListObj rightPadListObj
        leftPadListList rightPadListList
        leftPadStr rightPadStr

        sliceListN sliceStrN
        spansOf
        mapCons
        mapPairs mapPairs'

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

        optionals optional
        flatten

        lengthsEq stringLengthsEq
        ;
    };

    # addLists : [a] -> [a] -> [a]
    addLists = a: b: a ++ b;

    # addStrings : String -> String -> String
    addStrings = a: b: a + b;

    # sublist : Int -> Int -> [a] -> [a]
    sublist = start: count: list: let
        len = length list;

        trueCount = if (start + count) < len
            then count
            else if start >= len
                then 0
                else (len - start);
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
    repeatStr = str: count: concatStrings (genList' str count);

    # repeatStr : [a] -> Int -> [a]
    repeatList = list: count: concatLists (genList' list count);

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
    
    # genList' : a -> Int -> [a]
    genList' = o genList const;

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
        mkPad = genList';
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

    # mapPairs : ((a, a) -> b) -> [a] -> [b]
    mapPairs = mapCons 2;

    # mapPairs' : (a -> a -> b) -> [a] -> [b]
    mapPairs' = o mapPairs uncurry;

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
    asciiTable = import ./ascii-table.nix;

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

    	spans = mapPairs' getSlice ixs';
    in
    	assert isLambda pred;
    	assert isList list;

		if len == 0
			then list
			else spans;

    # optionals : Bool -> [a] -> [a];
    optionals = testRes: arg:
        if testRes then arg else [];

    # optionals : Bool -> a -> [a];
    optional = testRes: arg: optionals testRes [ arg ];

    # NestedList : Type -> Type
    # NestedList a = [a | NestedList a]

    # flatten : NestedList a -> [a]
    flatten = list: let
        fn = v: if isList v then flatten v else [v];
    in
        assert isList list;

        if all (v: !(isList v)) list
            then list
            else concatLists (map fn list);

    genericLengthsEq = getLen: a: b: (getLen a) == (getLen b);

    lengthsEq = genericLengthsEq length;
    stringLengthsEq = genericLengthsEq stringLength;
}
