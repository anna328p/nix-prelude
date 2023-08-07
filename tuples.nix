{ L, ... }:

with L; let
	inherit (builtins)
		isList length elemAt genList all
		isInt isFunction
		map foldl'
		;
in rec {
	exports = self: { inherit (self)
		isTuple isPair
		tupleMatches pairMatches

		singleton
		append
		curry curryN
		uncurry uncurryN

		mkTuple mkPair
		fst snd
		minListLength
		zip mapPairs zipMap
		pairAt
		;
	};

	# isTuple : Int -> [a] -> Bool
	isTuple = n: val:
		assert isInt n;
		isList val && (length val) == n;

	# isPair : [a] -> Bool
	isPair = isTuple 2;

    tupleMatches = n: let
        fn = l: r: lengthsEq l r && all id (zipMap id l r);
    in
        curryN fn n;

    pairMatches = f: g: p:
        assert isPair p;
        f (fst p) && g (snd p);

	# singleton : a -> [a]
	singleton = val: [ val ];

	# append : [a] -> a -> [a]
	append = xs: x:
	    assert isList xs;
	    xs ++ [x];

    # CurryFn : Nat -> Type -> Type -> Type
    # CurryFn 1 a b = a -> b
    # CurryFn n a b = a -> CurryFn (n - 1) a b

    # curry : ([a] -> b) -> Nat n -> CurryFn n a b
    curryN = f: n:
        assert isNat n;
        foldl' compose2 f (genList' append n) [];

    # mkTuple : Nat n -> curryFn n a [a]
    mkTuple = curryN id;

	# mkPair : a -> b -> (a, b)
	mkPair = a: b: [ a b ];
	
	# fst : (a, b) -> a
	fst = pair:
		assert isPair pair;
		elemAt pair 0;

	# snd : (a, b) -> b
	snd = pair:
		assert isPair pair;
		elemAt pair 1;
	
	# curry : ((a, b) -> c) -> a -> b -> c
	curry = fn: a: b:
		assert isFunction fn;
		fn [ a b ];

    # uncurry : Nat n -> (Any -> Any) -> Tuple n -> Any
    uncurryN = n: fn: xs:
        assert isNat n;
        assert isFunction fn;
        assert isTuple n xs;
        foldl' id fn xs;

	# uncurry : (a -> b -> c) -> (a, b) -> c
	uncurry = fn: pair:
		assert isFunction fn;
		assert isPair pair;
		apply2 fn fst snd pair;

	# minListLength : [a] -> [b] -> Int
	minListLength = left: right:
		assert isList left;
		assert isList right;
		(on min length) left right;

	# zip : [a] -> [b] -> [(a, b)]
	zip = left: right: let
		len = minListLength left right;
	in
		genList (pairAt left right) len;
	
	# mapPairs : (a -> b -> c) -> [(a, b)] -> c
	mapPairs = fn: list:
		assert isFunction fn;
		assert isList list;
		assert all isPair list;
		map (uncurry fn) list;
	
	# pairAt : [a] -> [b] -> Int -> (a, b)
	pairAt = left: right: apply2 mkPair (elemAt left) (elemAt right);

	# zipMap : (a -> b -> c) -> [a] -> [b] -> [c]
	zipMap = fn: left: right: let
		len = minListLength left right;
	in
		assert isFunction fn;
		genList (apply2 fn (elemAt left) (elemAt right)) len;
}