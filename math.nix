{ self, ... }:

let
	inherit (builtins)
		floor
		elemAt
		bitAnd
		isList
		length
		head
		genList
		foldl'
		add

		toString
		toJSON
		trace
		;

	inherit (self)
		isPositiveInt
		;
in rec {
	exports = self: { inherit (self)
		pow pow2
		log2f ln
		pow2f powf
		sqrt cbrt
		sin cos tan cot
		matmul
		;
	};

	pi = 3.141592653589793;
	e = 2.718281828459045;

	# exponentiation by squaring
	# pow : Int -> Int -> Int
	pow = base: exp: let
		pow' = b: e: let
			expEven = (bitAnd e 1) == 0;
		in
			if e == 0 then
				1
			else if expEven then
				pow' (b * b) (e / 2)
			else
				b * pow' (b * b) ((e - 1) / 2);
	in
		assert isPositiveInt exp;
		pow' base exp;

	pow2 = import data/pow2.nix;

	# TODO: higher accuracy and faster algorithms

	# log2f : Float -> Float
	log2f = let
		maxIter = 20;

		g = x:
			if (x < 2.0 || x >= 4.0) then
				let rg = g (x * x);
				in [ (1 + elemAt rg 0) (elemAt rg 1) ]
			else
				[ 0 x ];

		f = iter: n:
			if n == 1.0 then
				0.0
			else if n < 1.0 then
				(-1.0) + (f iter (n * 2.0))
			else if n > 2.0 then
				1.0 + (f iter (n / 2.0))
			else
				let
					rz = g n;
					m = elemAt rz 0;
					z = elemAt rz 1;

					nextTerm = if iter > 0
						then f (iter - 1) (z / 2.0)
						else 0.0;
				in
					(1.0 / pow2 m) * (1 + nextTerm);
	in
		f maxIter;

	ln2 = 0.6931471805599453;

	ln = x: log2f x * ln2;

	pow2f = f: let
		taylor = x: let
			t0 = 1.0;
			t1 = t0 * x * ln2 / 1.0;
			t2 = t1 * x * ln2 / 2.0;
			t3 = t2 * x * ln2 / 3.0;
			t4 = t3 * x * ln2 / 4.0;
			t5 = t4 * x * ln2 / 5.0;
			t6 = t5 * x * ln2 / 6.0;
			t7 = t6 * x * ln2 / 7.0;
		in
			t0 + t1 + t2 + t3 + t4 + t5 + t6 + t7;

		iPart = floor f;
		fPart = f - iPart;

		iexp = 1.0 * (pow2 iPart);
		fexp = taylor fPart;
	in
		if fPart == 0.0 then
			iexp
		else
			iexp * fexp;

	# TODO: replace with a real implementation
	powf = base: exp: let
		iPart = floor exp;
		fPart = exp - iPart;

		iexp = 1.0 * (pow base iPart);
		fexp = pow2f (fPart * log2f base);
	in
		if fPart == 0.0 then
			iexp
		else
			iexp * fexp;

	# TODO: better approximation
	sqrt = x: powf x 0.5;
	cbrt = x: powf x (1.0 / 3.0);

	sin = x: let
		taylor = a: let
			t0 = a;
			t1 = -t0 * a * a / 6.0;
			t2 = -t1 * a * a / 20.0;
			t3 = -t2 * a * a / 42.0;
			t4 = -t3 * a * a / 72.0;
			t5 = -t4 * a * a / 110.0;
		in
			t0 + t1 + t2 + t3 + t4 + t5;

		clamped = x - (floor ((x + pi) / (2*pi))) * 2*pi;
		q2 = pi - clamped;
		q3 = -pi - clamped;
	in
		if x == 0 || x == -pi then 0
		else if x == pi / 2 || x == -pi / 2 then 1
		else if clamped < -pi / 2 then taylor q3
		else if clamped < pi / 2 then taylor clamped
		else taylor q2;

	# TODO: use the cosine taylor series for better performance + precision
	cos = x: sin (x + pi / 2);

	tan = x: sin x / cos x;
	cot = x: cos x / sin x;

	matmul = a: b: let
		nra = length a;
		nca = length (head a);
		nrb = length b;
		ncb = length (head b);

		m = nra;
		n = nca;
		p = ncb;

		getRowA = i: elemAt a i;
		getColB = j: map (r: elemAt r j) b;

		dot = v1: v2: foldl' add 0 (genList (i: elemAt v1 i * elemAt v2 i) n);
	in
		assert isList a;
		assert isList (head a);
		assert isList b;
		assert isList (head b);

		assert nca == nrb;

		genList (i: genList (j: dot (getRowA i) (getColB j)) p) m;
}
