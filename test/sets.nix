{ self, ... }:

let
	inherit (self.testing) runTests describe;

	inherit (self.sets)
		diffSets
		;

in runTests [
	(describe "diffSets" ({ it, ... }: [
		(it "returns an empty diff for two empty sets" {
			expr = diffSets {} {};
			expect = {};
		})

		(it "shows an extra element on the left" {
			expr = diffSets { a = 1; b = 2; } { b = 2; };
			expect = { left = { a = 1; }; right = { }; };
		})
	]))
]
