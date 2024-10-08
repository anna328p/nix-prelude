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

		lib = import ./. { inherit flakes; };

		checks = let
			inherit (builtins)
				all
				attrValues
				mapAttrs
				trace
				;

			inherit (self.lib)
				id
				genSet
				unreachable
				const
				;

			dummyDrv = derivation {
				name = "_";
				builder = "builtin:buildenv";
				system = "builtin";
				derivations = [];
				manifest = "/dev/null";
			};

			eachSystem = fn: genSet fn (import systems);

			testToDrv = ctxName: result: let
				passes = map
					(v: trace
						"    => ${v.msg}"
						v.allPassed)
					(attrValues result);

				passes' = trace "-> running tests for ${ctxName}"
					passes;
			in
				if (all id passes') then
					trace "=> all tests for ${ctxName} pass"
						dummyDrv
				else
					unreachable;

			testResults = mapAttrs testToDrv
				(import ./test { inherit flakes; });
		in
			eachSystem (const testResults);
	};
}
