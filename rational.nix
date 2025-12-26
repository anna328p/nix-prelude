{ self, ... }:

let
	inherit (builtins)
		elemAt
		bitAnd
		;

	inherit (self)
		pow
		;
in rec {
	exports = self: { inherit (self)
		r num den
		intToRational rationalToFloat
		gcd lcm
		reduce
		radd rsub rmul rdiv
		rpow
		rinv
		;
	};

	r = n: d: [ n d ];
	num = v: elemAt v 0;
	den = v: elemAt v 1;

	intToRational = n: r n 1;
	rationalToFloat = v: 1.0 * num v / den v;

	# Stein's algorithm
	gcd = u: v:
		# trivial cases
		if u == 0 then v
		else if v == 0 then u
		else if u == v then u
		else let
			aEven = (bitAnd u 1) == 0;
			bEven = (bitAnd v 1) == 0;
		in
			if aEven && bEven then 2 * gcd (u / 2) (v / 2)
			else if aEven then gcd (u / 2) v
			else if bEven then gcd u (v / 2)
			else if u <= v then gcd u (v - u)
			else gcd v (u - v);

	lcm = a: b: a * b / gcd a b;

	reduce = v: let
		n = num v;
		d = den v;
		g = gcd n d;
	in
		r (n / g) (d / g);

	radd = a: b: let
		ad = den a;
		bd = den b;
		l = lcm ad bd;

		res = r (num a * (l / ad) + num b * (l / bd)) l;
	in
		reduce res;

	rsub = a: b:
		radd a (r -(num b) (den b));

	rmul = a: b:
		reduce (r (num a * num b) (den a * den b));

	rdiv = a: b:
		reduce (r (num a * den b) (den a * num b));

	rpow = base: exp:
		reduce (r (pow (num base) exp) (pow (den base) exp));

	rinv = v: r (den v) (num v);
}
