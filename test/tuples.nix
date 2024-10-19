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
		(it "matches a triple correctly" {
			expr = tupleMatches 3
				isInt isFloat isNull
				[ 1 1.0 null ];

			expect = true;
		})

		(it "works on pairs" {
			expr = tupleMatches 2
				isInt isFloat
				[ 1 1.0 ];

			expect = true;
		})

		(it "fails on a tuple of the wrong length" {
			expr = tupleMatches 3
				isInt isFloat isNull
				[ 1 1.0 ];

			expect = false;
		})

		(it "throws on a non-tuple" {
			expr = tryEval
				(tupleMatches 3
					isInt isFloat isNull
					{ });

			predicate = v: v.success == false;
		})

		(it "throws for length 0" {
			expr = tryEval (tupleMatches 0 [ ]);

			predicate = v: v.success == false;
		})
	]))
]
