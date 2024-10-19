{ self, ... }:

let
	inherit (self.testing) runTests describe;

	inherit (self.base64)
		toBase64
		;
in runTests [
	(describe "toBase64" ({ it, ... }: [
		(it "converts a string to base64" {
			expr = toBase64 "hello";
			expect = "aGVsbG8=";
		})

		(it "converts an empty string to an empty string" {
			expr = toBase64 "";
			expect = "";
		})
	]))
]
