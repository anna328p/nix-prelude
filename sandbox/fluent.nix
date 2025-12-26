let
	inherit (builtins)
		split
		filter
		isString
		foldl'
		concatStringsSep
		length
		genList
		elemAt
		;

	wrapStr = obj: let
		f = (self: rec {
			unwrap = obj;

			splitOn = sep: wrapList (filter isString (builtins.split sep self.unwrap));
			split = self.splitOn "\s";
		});

		x = f x;
	in
		x;

	wrapList = list: let
		f = (self: rec {
			unwrap = list;

			reverse = let
				len = length list;
				res = genList (i: elemAt self.unwrap (len - i - 1)) len;
			in
				wrapList res;

			join = wrapStr (concatStringsSep "" self.unwrap);
		});

		x = f x;
	in
		x;
	
in {
	res = (wrapStr "hello, world").split.reverse.join.unwrap;
}
