{ flakes, ... }:

let
	self = flakes.self.lib;

	testFiles = [
		./introspection.nix
		./base.nix
		./base64.nix
		./lua.nix
	];

	runTests = files: let
		import' = f: import f { inherit self; };
	in
		builtins.listToAttrs
			(builtins.map
				(p: {
					name = self.abbreviatePath p;
					value = self.deepForce (import' p);
				})
				files);
in
	runTests testFiles
