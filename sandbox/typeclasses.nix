with builtins;
let
	flip = f: a: b: f b a;

	mkSemigroup = { op }@args: args;
	mkMonoid = semigroup: { id }@args: semigroup // args;

	impls = rec {
		List.Semigroup.concat = mkSemigroup { op = l: r: l ++ r; };
		List.Monoid.concat = mkMonoid List.Semigroup.concat { id = []; };

		String.Semigroup.concat = mkSemigroup { op = l: r: l + r; };
		String.Monoid.concat = mkMonoid String.Semigroup.concat { id = ""; };
	};

	__findFile = _: path: let
		components = filter
			(v: isString v && (stringLength v) > 0)
			(split "/" path);
	in
		
		assert (length components) > 0;
		foldl' (flip getAttr) impls components;

	join = m: foldl' m.op m.id;

in {
	_ = __findFile;

	stringExample = join<String/Monoid/concat> [ "meow " "meow " "meow" ];

	listExample = join<List/Monoid/concat> [ [ 1 2 ] [ 3 4 5 ] [ 6 ] ];
}
