{ self, ... }:

let
	inherit (builtins)
		tryEval
		isInt isFloat isNull
		;
	
	inherit (self.testing) runTests for;
	
	inherit (self.tuples)
		isTuple
		tupleMatches
		;
in runTests [
	(for "isTuple" ({ it, ... }: [
		(it "identifies a valid tuple" {
			expr = isTuple 2 [ 1 2 ];
			expect = true;
		})

		(it "fails on something that is not a tuple" {
			expr = isTuple 2 { };
			expect = false;
		})

		(it "checks for the correct length" {
			expr = isTuple 3 [ 1 2 ];
			expect = false;
		})
	]))


	(for "tupleMatches" ({ it, ... }: [
		(it "works" {
			expr = tupleMatches 3
				isInt isFloat isNull
				[ 1 1.0 null ];

			expect = true;
		})
	]))
]
