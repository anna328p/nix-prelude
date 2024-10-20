{ self, ... }:

let
	inherit (builtins)
		tryEval
		;

	inherit (self)
		deepForce
		;

	inherit (self.testing) runTests describe;

	inherit (self.lua)
		toLuaLiteral
		;
in runTests [
	(describe "toLuaLiteral" ({ it, ... }: [
		(it "processes an integer" {
			expr = toLuaLiteral 3;
			expect = "3";
		})

		(it "processes an empty string" {
			expr = toLuaLiteral "";
			expect = ''""'';
		})

		(it "throws on a function" {
			expr = (tryEval (deepForce (toLuaLiteral (a: a)))).success;
			expect = false;
		})
	]))
]
