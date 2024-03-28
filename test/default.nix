{ prelude, ... }:

let
	testFiles = [
		./introspection.nix
	];

	runTests = files: let
		deepSeq' = v: builtins.deepSeq v v;

		import' = f: import f { inherit prelude; };
	in
		builtins.map (f: deepSeq' (import' f)) files;
in
	runTests testFiles
