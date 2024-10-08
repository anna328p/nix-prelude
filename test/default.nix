{ flakes, ... }:

let
	self = flakes.self.lib;

	testFiles = [
		./introspection.nix
		./base.nix
		./base64.nix
	];

	runTests = files: let
		import' = f: import f { inherit self; };
	in
		builtins.listToAttrs
			(builtins.map
				(path: {
					name = builtins.toString (builtins.baseNameOf path);
					value = self.deepForce (import' path);
				})
				files);
in
	runTests testFiles
