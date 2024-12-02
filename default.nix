{ flakes }:

let
    inherit (builtins)
        foldl' mapAttrs attrValues
        throw addErrorContext
        isFunction isAttrs
        ;

    # fix : (a -> a) -> a
    fix = f: let x = f x; in x;


    # foldSets : [Set] -> Set
    foldSets = foldl' (a: b: a // b) { };


    # mapAttrVals : (a -> b) -> Set a -> Set b
    mapAttrVals = fn: mapAttrs (_: fn);

	throwIf = cond: msg: val: if cond then throw msg else val;
	throwIfNot = cond: throwIf (!cond);

    # Mod = { * } -> Set
    # callMod' : Set -> Set -> (Mod -> Set) -> Set -> Set
    callMod' = self: defaultArgs: mod: args: let
        args' = { inherit self; } // defaultArgs // args;

    	res = mod args';
    in
    	addErrorContext
    		"while evaluating a library module" (
    	throwIfNot (isFunction mod)
    		"expected module to be a function" (
    	throwIfNot (isAttrs res)
			"expected module to return an attribute set"
			res
		));

	importPath = call: path: let
		res = call (import path) { };
	in
		addErrorContext
			"while importing a library module at ${path}" (
		throwIfNot (res ? exports)
			"expected module output to contain an attr named `exports`" (
		throwIfNot (isFunction res.exports)
			"expected attr `exports` to contain a function"
			res
		));

    # using' : ((Mod -> Set) -> Set -> Set) -> Set Path -> (Set -> Set) -> Set
    using' = call: inputs: fn: let
        # importMod : Path -> Set
        importMod = importPath call;

        # getExports : Set -> Set
        getExports = mod: mod.exports mod;

        # mods : Set Set
        mods = mapAttrVals importMod inputs;
        # exports : [Set]
        exportSets = attrValues (mapAttrVals getExports mods);

        env = mods // (foldSets exportSets);
    in env // fn env;


    # mkLibrary : Set -> Mod -> Set
    mkLibrary = extraArgs: fn: let
        inner = self: let
            # args : Set
            args = extraArgs // { inherit using; };

            # call : (Mod -> Set) -> Set -> Set
            call = callMod' self args;

            # using : Set Path -> (Set -> Set) -> Set
            using = using' call;
        in call fn { };
    in fix inner;


in mkLibrary {
    parsec = flakes.parsec.lib;
} ({ using, ... }:
    using {
        base = ./base.nix;
        numeric = ./numeric.nix;

        strings-lists = ./strings-lists.nix;
        tuples = ./tuples.nix;
        sets = ./sets.nix;

        introspection = ./introspection.nix;
        debugging = ./debugging.nix;

        _urlencode = ./urlencode.nix;
        base64 = ./base64.nix;
        prng = ./prng.nix;
        hashes = ./hashes.nix;

        files = ./files.nix;

        misc = ./misc.nix;
        helpers = ./helpers.nix;

        lua = ./lua.nix;

        testing = ./testing.nix;
    } (_: {
		inherit mkLibrary;
	})
)
