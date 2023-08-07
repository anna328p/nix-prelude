{
	description = ''
		Base library for programming in Nix, with no Nixpkgs dependencies
	'';

	inputs = {
        parsec.url = github:milahu/nix-parsec;
	};

	outputs = { self
		, parsec
	}@flakes: {
		lib = import ./. { inherit flakes; };
	};
}
