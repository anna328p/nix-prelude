{
	description = ''
		Base library for programming in Nix, with no Nixpkgs dependencies
	'';

	inputs = {
        parsec.url = "github:milahu/nix-parsec";
        systems.url = "github:nix-systems/default";
	};

	nixConfig = {
		extra-experimental-features = "pipe-operators";
	};

	outputs = { self, parsec, systems }@flakes: {

		inputs = flakes;

		lib = import ./. { inherit flakes; };

		checks = let
			inherit (builtins) mapAttrs;
			inherit (self.lib) genSet const;

			eachSystem = fn: genSet fn (import systems);

			testResults = mapAttrs self.lib.testing.testToDrv
				(import ./test { inherit flakes; });
		in
			eachSystem (const testResults);
	};
}
