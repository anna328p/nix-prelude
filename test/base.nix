{ self, ... }:

let
	inherit (builtins)
		tryEval
		;
	
	inherit (self.testing) runTests describe;
	
	inherit (self.base)
		pipe pipe'
		fix
		isLambda
		;
in runTests [
	(describe "pipe" ({ it, ... }: [
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

	(describe "pipe'" ({ it, ... }: [
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

	(describe "fix" ({ it, ... }: [
		(it "establishes a fixed point" {
			expr = fix (self: {
				a = 1;
				b = self.a + 1;
			});

			expect = { a = 1; b = 2; };
		})
	]))

	(describe "isLambda" ({ it, ... }: [
		(it "returns false for a non-function" {
			expr = isLambda 1;
			expect = false;
		})

		(it "returns true for a function" {
			expr = isLambda (a: a);
			expect = true;
		})

		(it "returns true for a valid functor attrset" {
			expr = let
				set = { __functor = self: arg: [ self arg ]; };
			in
				isLambda set;

			expect = true;
		})

		(it "returns false for an invalid functor attrset" {
			expr = let
				set = { __functor = self: [ self ]; };
			in
				isLambda set;

			expect = false;
		})
	]))
]
