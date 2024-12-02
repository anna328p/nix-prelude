{ self, ... }:

let
	inherit (builtins)
		readDir
		mapAttrs
		isAttrs
		elem
		attrNames
		concatStringsSep
		substring
		;

	inherit (self)
		filterSet
		mapSetRec
		;
in rec {
	exports = self: { inherit (self)
		readTree
		;
	};

	readTree = path:
		mapAttrs
			(name: type:
				if type == "directory"
					then readTree "${path}/${name}"
					else type)
			(readDir path);

	findModules = path: let
		isModule = v: isAttrs v && elem "default.nix" (attrNames v);

		joinPath = concatStringsSep "/";
	
		recurse = path: tree: let
			tree' = filterSet (k: v: (substring 0 1 k) != ".") tree;
		in
			if isModule tree
				then joinPath path
				else if isAttrs tree
					then filterSet
						(_: v: v != false && v != { })
						(mapAttrs (k: recurse (path ++ [ k ])) tree')
					else false;

		tree = readTree path;
		res = recurse [] tree;
	in
		mapSetRec (_: v: path + ("/${v}")) res;
}
