{ flakes }:

let
    inherit (builtins)
        foldl' mapAttrs attrValues;

    # fix : (a -> a) -> a
    fix = f: let x = f x; in x;


    # foldSets : [Set] -> Set
    foldSets = foldl' (a: b: a // b) { };


    # mapAttrVals : (a -> b) -> Set a -> Set b
    mapAttrVals = fn: mapAttrs (_: fn);


    # Mod = { * } -> Set
    # callMod' : Set -> Set -> (Mod -> Set) -> Set -> Set
    callMod' = self: defaultArgs: mod: args: let
        args' = { L = self; } // defaultArgs // args;
    in mod args';


    # using' : ((Mod -> Set) -> Set -> Set) -> Set Path -> (Set -> Set) -> Set
    using' = call: inputs: fn: let
        # importMod : Path -> Set
        importMod = path: call (import path) { };

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
        colors = ./colors.nix;
        _urlencode = ./urlencode.nix;
        base64 = ./base64.nix;
        misc = ./misc.nix;

        introspection = ./introspection.nix;

        lua = ./lua.nix;
    } (_: {})
)
