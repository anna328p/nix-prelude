{ self, ... }:

let
	inherit (builtins)
		addErrorContext
		any all
		filter
		concatLists concatMap
		attrValues
		trace
		deepSeq
		toJSON
		length
		seq
		;
	
	inherit (self)
		concatLines
		pairsToSet
		id
		unreachable
		toValidDrvName
		optional optionals
		when
		;

in rec {
	exports = self: { };

	runTests = list: pairsToSet (map (r: [ r.subject r ]) list);

	describe = subject: fn: let
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

			passes = filter (r: r.pass or false) results;
			failures = filter (r: !(r.pass or false)) results;

			anyPassed = (length passes) > 0;
			allPassed = (length failures) == 0;
			somePassed = anyPassed && !allPassed;
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
		err = msg: "!! ${msg}";

		failMsg = subject: t: let
			positionOf = self.showPosOf t.orig;

			where = when [
				(t ? expect)    "at ${positionOf "expr"}"
				(t ? predicate) "at ${positionOf "predicate"}"
			] unreachable;

			context = "while checking if ${subject} ${t.what}:";

			failure = when [
				(t ? expect)    "expected ${toJSON t.expect}; got ${toJSON t.expr}"
				(t ? predicate) "predicate is false; got ${toJSON t.expr}"
			] unreachable;

			message = [
				"  !! ${context}"
				"  !!   ${where}:"
				"  !!   ${failure}"
			];
		in
			message;

		groupSummary = group: let
			inherit (group) subject allPassed somePassed passes failures;
		in
			concatLists [
				(optional allPassed "${subject} passed all tests:")
				(optional somePassed "${subject} successfully:")
				(map (t: "  - ${t.what}") passes)

				(optional (!allPassed) "${subject} has failures:")
				(concatMap (failMsg subject) failures)
			];

		groups = attrValues result;

		noFailures = all (g: g.allPassed) groups;
		someFailures = !noFailures;

		print = v: trace v null;
		printLines = map print;

		output = concatLists [
			[ "-> test results for ${ctxName}:" ]
			(concatMap groupSummary groups)

			(optional noFailures "=> all tests for ${ctxName} pass")
			(optional someFailures "!! some tests for ${ctxName} failed")
			[ "" ]
		];

		drv = if noFailures
			then dummyDrvPass ctxName
			else dummyDrvFail ctxName;
	in
		deepSeq (printLines output) drv;
}
