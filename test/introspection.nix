{ self, ... }:

let
	inherit (builtins)
		tryEval
		;

	inherit (self.testing) runTests for;

	inherit (self.introspection)
		hasEllipsis'
		hasEllipsis
		hasFormals'
		hasFormals
		lambdaArgName'
		lambdaArgName
		;
	
	# runSameTests : Dict Lambda -> List Test -> Any
	runSameTests = set: tests: let
		inherit (builtins) mapAttrs attrValues;

		tested = mapAttrs (name: value: for name (tests value)) set;
	in
		attrValues tested;

in runTests ((runSameTests {
	inherit hasEllipsis hasEllipsis';
} (fn: { it, ... }: [
	(it "throws when not passed a function" {
		expr = tryEval (fn 0);
		expect = { success = false; value = false; };
	})

	(it "returns null for a function without a set pattern" {
		expr = fn (a: a);
		predicate = v: v == null;
	})

	(it "returns false for a pattern without ellipses" {
		expr = fn ({ a }: a);
		expect = false;
	})

	(it "returns true for a pattern with ellipses" {
		expr = fn ({ a, ... }: a);
		expect = true;
	})

	(it "works for functions with rest-patterns" {
		expr = fn ({ a, ... }@rest: rest);
		expect = true;
	})
])) ++ (runSameTests {
	inherit hasFormals hasFormals';
} (fn: { it, ... }: [
	(it "throws when not passed a function" {
		expr = tryEval (fn 0);
		expect = { success = false; value = false; };
	})

	(it "returns false for a function without a pattern" {
		expr = fn (a: a);
		expect = false;
	})

	(it "returns true for a function with a pattern" {
		expr = fn ({ a }: a);
		expect = true;
	})

	(it "returns true for a function with a rest-pattern" {
		expr = fn ({ a }@rest: rest);
		expect = true;
	})

	(it "works with functions that have ellipses" {
		expr = fn ({ a, ... }@rest: rest);
		expect = true;
	})
])) ++ (runSameTests {
	inherit lambdaArgName lambdaArgName';
} (fn: { it, ... }: [
	(it "throws when not passed a function" {
		expr = tryEval (fn 0);
		expect = { success = false; value = false; };
	})

	(it "returns the name of the lambda argument" {
		expr = fn (meow: meow);
		expect = "meow";
	})

	(it "returns null for functions with only a pattern" {
		expr = fn ({ a }: a);
		predicate = v: v == null;
	})

	(it "returns the name of the rest-pattern" {
		expr = fn ({ a, ... }@rest: rest);
		expect = "rest";
	})

	(it "does not fall for misleading names" {
		expr = fn ({ name, ... }@rest: rest);
		expect = "rest";
	})
])))
