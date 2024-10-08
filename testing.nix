{ self, ... }:

let
	inherit (builtins)
		addErrorContext
		all
		filter
		concatLists
		;
	
	inherit (self)
		concatLines
		pairsToSet
		;
in {
	exports = self: { inherit (self) ; };

	runTests = list: pairsToSet (map (r: [ r.subject r ]) list);

	for = subject: fn: let
		it = what: { expr, expect ? null, predicate ? null }:
			addErrorContext "while testing whether ${subject} ${what}" (
				assert (expect != null) || (predicate != null);
				{
					inherit what expr;
				} // (if expect != null
					then { inherit expect; pass = expect == expr; }
					else { inherit predicate; pass = predicate expr; }
				));

		env = { inherit it; };

		results = fn env;
	in
		rec {
			inherit subject results;
			allPassed = all (r: r.pass or false) results;
			passes = filter (r: r.pass or false) results;
			failures = filter (r: !(r.pass or false)) results;

			msg = if allPassed then
				"${subject} passed all checks"
			else concatLines (concatLists [
				[ "${subject} failed the following tests:" ]
				(map (t: "  - it ${t.what}") failures)
			]);
		};
}
