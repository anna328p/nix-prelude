{ self, ... }:

let
	inherit (builtins)
		listToAttrs
		unsafeGetAttrPos
		;

	inherit (self)
		flip
		mkMapping
		;
in rec {
	exports = self: { inherit (self)
		abbreviatePath
		formatPos
		showPosOf

        unreachable
        unreachable'
        unimplemented

		__

		unrollArgSequence'
		unrollArgSequence
		;
	};

	# abbreviatePath : Path -> String
	abbreviatePath = p: "[...]/" + (baseNameOf (dirOf p)) + "/" + (baseNameOf p);

	formatPos = pos: let
		filename = abbreviatePath pos.file;
	in
		"${filename}:${toString pos.line}:${toString pos.column}";

	showPosOf = set: attr: self.formatPos (unsafeGetAttrPos attr set);

	unreachable = throw "took unreachable branch";
    unreachable' = pos: msg: throw "took unreachable branch at ${formatPos pos}: ${msg}";
    unimplemented = pos: msg: throw "unimplemented at ${formatPos pos}: ${msg}";

    __ = "579ab340-13a4-4467-81d1-32ae4b7d5d1e"; # uuidgen -r

    unrollArgSequence' = endRowPred: callback: {
        value = [];
        stack = [];

        __functor = self: arg: let
            newEntries = map (flip mkMapping arg) self.stack;

            value' = if endRowPred arg
                then self.value ++ newEntries
                else self.value;

            stack' = if endRowPred arg
                then [] 
                else self.stack ++ [ arg ];
        in
            if arg == __
                then callback self.value
                else self // {
                    value = value';
                    stack = stack';
                };
    };

    unrollArgSequence = unrollArgSequence' listToAttrs;
}
