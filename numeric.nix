{ self, ... }:

with self; let
	inherit (builtins)
		isInt
		;
in {
	exports = self: { inherit (self)
	    isPositive isNegative
	    isPositiveInt isNegativeInt
	    isNat
		min max modulo abs
		pow pow2 ceilDiv
		shiftLeft shiftRight
		;
	};

	# isPositive : Int -> Bool
	isPositive = n: n >= 0;

	# isNegative : Int -> Bool
	isNegative = n: n < 0;

	# isPositiveInt : Int -> Bool
	isPositiveInt = n: isInt n && isPositive n;

	# isNegativeInt : Int -> Bool
	isNegativeInt = n: isInt n && isNegative n;

	# isNat : Int -> Bool
	isNat = n: isInt n && n > 0;

	# min : Int -> Int -> Int
	min = a: b: if a < b then a else b;

	# max : Int -> Int -> Int
	max = a: b: if a > b then a else b;

	# modulo : Int -> Int -> Int
	modulo = a: b: a - (a / b) * b;

	# abs : Int -> Int
	abs = i: if isPositive i then i else -i;

	# pow : Int -> Int -> Int
	pow = base: exp:
		assert isPositiveInt exp;
		if exp == 0 then
			1
		else if exp == 1 then
			base
		else
			base * (pow base (exp - 1));

	pow2 = import data/pow2.nix;
	
	# ceilDiv : Int -> Int -> Int
	ceilDiv = a: b: let
		quotient = a / b;
	in
		assert isPositiveInt a;
		assert isPositiveInt b;

		if (quotient * b) < a
			then quotient + 1
			else quotient;

	# shiftRight : Int -> Int -> Int
	shiftRight = x: n:
		assert isInt x;
		assert isInt n;

		if n < 0 then
			shiftLeft x (-1 * n) 
		else if n > 63 then
			if x >= 0 then 0 else (-1)
		else
			x / (pow2 n);

	# shiftLeft : Int -> Int -> Int
	shiftLeft = x: n:
		assert isInt x;
		assert isInt n;

		if n < 0 then
			shiftRight x (-1 * n)
		else if n > 63 then
			0
		else
			x * (pow2 n);
}
