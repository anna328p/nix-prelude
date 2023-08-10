{ self, ... }:

let
	inherit (builtins)
		bitOr bitAnd bitXor
		genList foldl'
		elemAt
		;
in with self; rec {
	exports = self: { inherit (self)
		;
	};

	splitmix64 = {
		generate = state: let
			newState = state + -7046029254386353131;
			result = newState; 

			result' = (bitXor result (shiftRight result 30))
				* -4658895280553007687;

			result'' = (bitXor result' (shiftRight result' 27))
				* -7723592293110705685;
		in
			mkPair
				(bitXor result'' (shiftRight result'' 31))
				newState;
	};

	# xoshiro256**

	xoshiro256ss = rec {
		rol64 = x: k:
			if k == 0 then
				x
			else
				bitOr
					(shiftLeft x k)
					(bitAnd
						(shiftRight x (64 - k))
						((pow2 k) - 1));

		initState = seed: let
			sm = splitmix64.generate;

			zero = sm seed;
			one = sm (snd zero); 
			two = sm (snd one); 
			three = sm (snd two); 
		in
			[ (fst zero) (fst one) (fst two) (fst three) ];

		generate = state: let
			s = state;
			result = (rol64 ((elemAt s 1) * 5) 7) * 9;
			t = shiftLeft (elemAt s 1) 17;

			two' = bitXor (elemAt s 2) (elemAt s 0);
			three' = bitXor (elemAt s 3) (elemAt s 1);
			one' = bitXor (elemAt s 1) two';
			zero' = bitXor (elemAt s 0) three';

			two'' = bitXor two' t;
			three'' = rol64 three' 45;
		in
			mkPair
				result
				[ zero' one' two'' three'' ];
	};

	iterate = fn: state: n: let
		nulls = genList (const null) n;
	in
		foldl'
			(acc: val: let res = fn (snd acc);
				in mkPair
					(append (fst acc) (fst res))
					(snd res))
			(mkPair [] state)
			nulls;
}
