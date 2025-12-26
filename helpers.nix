{ self, ... }:

let
	inherit (builtins)
		listToAttrs
		unsafeGetAttrPos
		split
		isList
		elemAt
		length
		stringLength
		;

	inherit (self)
		flip
		mkMapping
		match'
		repeatStr
		concatStrings
		;
in rec {
	exports = self: { inherit (self)
		when

		invertPred

		abbreviatePath
		formatPos
		showPosOf

		isValidDrvName
		toValidDrvName

        unreachable
        unreachable'
        unimplemented

		__

		unrollArgSequence'
		unrollArgSequence
		;
	};

	when = entries: fallback: let
		len = length entries;
		nPairs = len / 2;
		lastPair = nPairs - 1;

		getCondition = n: elemAt entries (n * 2);
		getConsequent = n: elemAt entries (n * 2 + 1);

		step = index:
			if getCondition index
				then getConsequent index
				else if index == lastPair
					then fallback
					else step (index + 1);
	in
		assert len / 2 * 2 == len; # even number of entries

		if len == 0
			then fallback
			else step 0;

	# invertPred : (a -> Bool) -> (a -> Bool)
	invertPred = pred: x: !(pred x);

	# abbreviatePath : Path -> String
	abbreviatePath = p: (baseNameOf (dirOf p)) + "/" + (baseNameOf p);

	formatPos = pos: let
		filename = abbreviatePath pos.file;
	in
		"${filename}:${toString pos.line}:${toString pos.column}";

	showPosOf = set: attr: self.formatPos (unsafeGetAttrPos attr set);

	drvNameFirst = "a-zA-Z0-9_+?=-";
	drvNameChar = "." + drvNameFirst;

	isValidDrvName = match'
		/* regex */ "^[${drvNameFirst}][${drvNameChar}]*$";

	toValidDrvName = str: let
		replaceWith = "?";
		a = split
			/* regex */ "(^[^${drvNameFirst}]|[^${drvNameChar}])"
			str;
		b = map
			(v: if isList v then
				repeatStr replaceWith (stringLength (elemAt v 0))
			else
				v)
			a;
		res = concatStrings b;
	in
		if isValidDrvName str then str else res;

	unreachable = throw "took unreachable branch";
    unreachable' = pos: msg: throw "took unreachable branch at ${formatPos pos}: ${msg}";
    unimplemented = pos: msg: throw "unimplemented at ${formatPos pos}: ${msg}";

    __ = "579ab340-13a4-4467-81d1-32ae4b7d5d1e"; # uuidgen -r

    unrollArgSequence' = callback: endRowPred: {
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
