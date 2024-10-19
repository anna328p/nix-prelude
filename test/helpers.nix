{ self, ... }:

let
	inherit (builtins)
		isList
		;
	
	inherit (self.testing) runTests describe;
	
	inherit (self.helpers)
		isValidDrvName
		toValidDrvName
		unrollArgSequence'
		unrollArgSequence
		__
		;
in runTests [
	(describe "unrollArgSequence" ({ it, ... }: [
		(it "works" {
			expr = unrollArgSequence isList
				"a" [ "a" "b" ]
				"b" "c" [ "c" "d" ]
				__;

			expect = {
				a = [ "a" "b" ];
				b = [ "c" "d" ];
				c = [ "c" "d" ];
			};
		})
	]))
]
