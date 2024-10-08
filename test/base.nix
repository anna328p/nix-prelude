{ self, ... }:

let
	inherit (builtins)
		tryEval
		;
	
	inherit (self.testing) runTests for;
	
	inherit (self.base)
		pipe pipe'
		fix
		isLambda
		;
in runTests [
	(for "pipe" ({ it, ... }: [
		(it "pipes a value through functions" {
			expr = let
				f = v: v + 5;
				g = v: 3 * v;
				h = v: builtins.toString v;
			in
				pipe 1 [ f g h ];

			expect = "18";
		})
	]))

	(for "pipe'" ({ it, ... }: [
		(it "pipes a value through functions" {
			expr = let
				f = v: v + 5;
				g = v: 3 * v;
				h = v: builtins.toString v;
			in
				pipe' [ f g h ] 1;

			expect = "18";
		})
	]))

	(for "fix" ({ it, ... }: [
		(it "establishes a fixed point" {
			expr = fix (self: {
				a = 1;
				b = self.a + 1;
			});

			expect = { a = 1; b = 2; };
		})
	]))
]
