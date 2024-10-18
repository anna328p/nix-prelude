{ self, ... }:

let
	inherit (builtins)
		addErrorContext
		all
		filter
		concatLists
		attrValues
		trace
		deepSeq
		toJSON
		;
	
	inherit (self)
		concatLines
		pairsToSet
		id
		unreachable
		toValidDrvName
		;

in rec {
	exports = self: { };

	runTests = list: pairsToSet (map (r: [ r.subject r ]) list);

	for = subject: fn: let
		it = what: { expr, expect ? null, predicate ? null }@orig:
			addErrorContext "while testing whether ${subject} ${what}" (
				assert (expect != null) || (predicate != null);
				{
					inherit what expr;
				} // (if expect != null
					then { inherit orig expect; pass = expect == expr; }
					else { inherit orig predicate; pass = predicate expr; }
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
				"${subject} passed all tests"
			else concatLines (concatLists [
				[ "${subject} fails when:" ]
				(map (t: "  - it ${t.what}") failures)
			]);
		};

	# Should always build; works anywhere
	dummyDrvPass = name: derivation {
		name = "placeholder-${toValidDrvName name}-test-pass";
		builder = "builtin:buildenv";
		system = "builtin";
		derivations = [];
		manifest = "/dev/null";
	};

	# Intentionally fails to build
	dummyDrvFail = name: derivation {
		name = "placeholder-${toValidDrvName name}-test-fail";
		builder = "builtin:buildenv";
		system = "builtin";
		derivations = [];
		manifest = ""; # nonexistent!
	};

	testToDrv = ctxName: result: let
		failMsg = subject: f: let
			prefix = "    !!";
			positionOf = self.showPosOf f.orig;
		in
			if f ? expect then let
				pos = positionOf "expr";
				in [
					"${prefix} while checking if ${subject} ${f.what}:"
					"    ${prefix} (at ${pos}) expected ${toJSON f.expect}; got ${toJSON f.expr}"
				]
			else if f ? predicate then let
				pos = positionOf "predicate";
				in [
					"${prefix} while checking if ${subject} ${f.what}:"
					"    ${prefix} (at ${pos}) predicate failed; got ${toJSON f.expr}"
				]
			else
				unreachable;

		passes = map
			(v: if (v.allPassed) then
					trace "    => ${v.msg}"
						v.allPassed
				else deepSeq
					(map (f: map (v: trace v null) (failMsg v.subject f)) v.failures)
					v.allPassed)
			(attrValues result);

		passes' = trace "-> test results for ${ctxName}:"
			passes;
	in
		if (all id passes') then
			trace "=> all tests for ${ctxName} pass"
				(trace "" dummyDrvPass ctxName)
		else
			trace "!! some tests for ${ctxName} failed"
				(trace "" dummyDrvFail ctxName);
}
