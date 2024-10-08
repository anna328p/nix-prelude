# MIT license
# originally based on https://github.com/milahu/nix-parsec

/*
	xml parser
	based on
	https://github.com/unhammer/tree-sitter-xml
	https://github.com/dorgnarg/tree-sitter-xml
	https://github.com/tree-sitter/tree-sitter-html

	TODO decode entities like &#10; -> \n
	TODO encode entities like \n -> &#10;
	TODO xpath selector parser + compiler
	TODO css selector parser + compiler
*/

{ nix-parsec, L, ... }:

let
	inherit (builtins)
		elemAt
		stringLength substring
		match
		;

	inherit (nix-parsec) lexer;

	inherit (nix-parsec.parsec)
		runParser
		bind pure

		alt sequence optional many many1 choice
		
		skipWhile skipWhile1 takeWhile1
		skipThen thenSkip
		
		string matching eof
		;

	inherit (L)
		pairsToSet
		compact flatten
		;

	# TODO bind all values from doctype
	inherit (import ./parse-xml-doctype.nix {
				inherit nix-parsec Name Space lexeme;
			})
		DoctypeDeclaration
		;

	isSpace = c: c == " " || c == "\n" || c == "\t";
	Space = skipWhile isSpace; # skipWhile: zero or more characters
	Space1 = skipWhile1 isSpace; # skipWhile1: one or more characters
	lexeme = lexer.lexeme Space;
	symbol = lexer.symbol Space;

	concatStrings = parser: bind parser (values: pure (L.concatStrings values));

	Element =
		alt
		EmptyTag
		Tag
	;

	doesMatch = pattern: str: match pattern str != null;
	lexemeMatching1 = pat: lexeme (takeWhile1 (doesMatch pat));

	Name = lexemeMatching1 "[a-zA-Z0-9_:-]";

	Hex = lexemeMatching1 "[0-9a-fA-F]";

	#Digits = lexer.decimal;
	Digits = lexemeMatching1 "[0-9]";

	# FIXME allow empty value?
	CharData = lexemeMatching1 "[^<&]";

	# this can be anything
	Chars = lexemeMatching1 ".";

	# TODO rename to CharDataInDoubleQuotes
	# FIXME allow empty value?
	ValueChunkInDoubleQuotes = lexemeMatching1 "[^<&\"]";

	# TODO rename to CharDataInSingleQuotes
	# FIXME allow empty value?
	ValueChunkInSingleQuotes = lexemeMatching1 "[^<&']";

	EmptyTag =
		bind
			(skipThen
				(symbol "<") # skip
				(thenSkip
					(sequence [ # TODO refactor: StartTag + EmptyTag
						Name
						Attributes
					])
					(sequence [ (optional Space) (string "/>") ]))) # skip

			# TODO refactor: StartTag + EmptyTag
			(values: pure {
				# sorted by alphabet
				attributes = pairsToSet (elemAt values 1);
				children = [];
				name = elemAt values 0;
				type = "tag";
				nameClose = "";
			});

	Tag = bind
		(sequence [
			StartTag
			#(optional CharData)
			(optional Content)
			EndTag
		])
		(values: pure (let
			startTag   = elemAt values 0;
			name       =     elemAt startTag 0;
			attributes =     pairsToSet (elemAt startTag 1);
			children   = elemAt (elemAt values 1) 0;
			endTag     = elemAt values 2;
		in
			if (name != endTag) then
				# TODO print source location
				throw "parse error: startTag != endTag: <${name}></${endTag}>"
			else {
				inherit attributes children name;
				nameClose = endTag; # debug
				type = "tag";
			}
		));

	StartTag =
		skipThen
			(symbol "<") # skip
			(thenSkip
				# TODO refactor: StartTag + EmptyTag
				(sequence [ Name Attributes ])
				(sequence [ (optional Space) (string ">") ])); # skip

	EndTag =
		skipThen
			(symbol "</") # skip
			(thenSkip
				Name
				(sequence [ (optional Space) (string ">") ]));

	Attributes = many (skipThen Space Attribute);

	Attribute = sequence [
		Name # key
		(skipThen (symbol "=") AttributeValue)
	];

	AttributeValue = 
		alt
			# double quotes
			(skipThen
				(symbol ''"'') # skip
				(thenSkip
					(concatStrings (many
						(alt
							ValueChunkInDoubleQuotes # /[^<&"]/
							Reference)))
					(symbol ''"'') # skip
				))
			# single quotes
			(skipThen
				(symbol "'") # skip
				(thenSkip
					(concatStrings (many
						(alt
							ValueChunkInSingleQuotes # /[^<&']/
							Reference)))
					(symbol "'") # skip
				));

	Reference = alt EntityReference CharacterReference;

	EntityReference = concatStrings (sequence [
		(symbol "&") # TODO symbol or string
		Name
		(symbol ";")
	]);

	CharacterReference = 
		concatStrings
			(alt
				(sequence [
					(symbol "&#") # TODO symbol or string
					Digits # /[0-9]+/
					(symbol ";")
				])
				(sequence [
					(symbol "&#x") # TODO symbol or string
					Hex # /[0-9a-fA-F]+/
					(symbol ";")
				]));

  Content = many (
    choice [
      Element
      Text
      Comment
      CdataSection
      /* TODO
      ProcessingInstructions
      */
    ]
  );

	Text = bind
		(concatStrings
			(many1 (choice [ CharData Reference ])))
		(value: pure {
			type = "text";
			inherit value;
			#children = [];
		});

	/* not used
	# Examine the next N characters without consuming them.
	# Fails if there is not enough input left.
	#   :: Parser String
	peekN = n: ps: let
		str = elemAt ps 0;
		offset = elemAt ps 1;
		len = elemAt ps 2;
	in
		if len >= n then
			[(substring offset n str) offset len]
		else {
			context = "parsec.peekN";
			msg = "expected ${n} characters";
		};
	*/

	# Consume zero or more characters until the stop string,
	# returning the consumed characters. Cannot fail.
	# based on parsec.takeWhile
	#   :: String -> Parser String
	takeUntil = stop: ps: let
		str = elemAt ps 0;
		valueStart = elemAt ps 1;
		len = elemAt ps 2;

		strLen = stringLength str;
		stopLen = stringLength stop;

		# Search for the next valueStart that violates the predicate
		seekEnd = position: let
			peekStop = substring position stopLen str;
		in
			if (position >= strLen) || (peekStop == stop)
				then position # break
				else seekEnd (position + 1); # continue

		valueEnd = seekEnd valueStart;
		# The number of characters we found
		valueLen = valueEnd - valueStart;

		foundStop = let
			peekStop = substring valueEnd stopLen str;
		in
			peekStop == stop;

		value = substring valueStart valueLen str;
		parseEnd = if foundStop then (valueEnd + stopLen) else valueEnd;
		remain = if foundStop then (len - valueLen - stopLen) else (len - valueLen);
	in
		[ value parseEnd remain ];

	Comment = 
		bind
			(skipThen
				(string "<!--") # skip
				(takeUntil "-->"))
			(value: pure { type = "comment"; inherit value; });

	CdataSection =
		bind
			(skipThen
				(string "<![CDATA") # skip
				(takeUntil "]]>"))
			(value: pure { type = "cdata"; inherit value; });

	Misc = choice [
		Comment
		#ProcessingInstructions # todo: <? ... ?>
		#Space # FIXME error: stack overflow (possible infinite recursion)
		Space1 # returns null
	];

	Prolog = sequence [
		(optional XMLDeclaration)
		(optional Misc)
		(optional (sequence [ DoctypeDeclaration (many Misc) ]))
	];

	/*
	# strict: allow only some attributes
	XMLDeclaration = sequence [
		#(string ''<?xml version="1.0"?>'') # ok
		# fixme
		(string "<?xml")
		#(string (" " + ''version="1.0"'')) # ok
		VersionInfo # FIXME error: value is a function while a list was expected
		#(optional EncodingDeclaration) # TODO
		#(optional SDDeclaration) # TODO
		(optional Space)
		(string "?>")
	];
	*/

	# loose: allow all attributes
	XMLDeclaration =
		bind
			(skipThen
				(string "<?xml")
				(thenSkip
					Attributes
					(sequence [ (optional Space) (string "?>") ])))
			(values: pure {
				type = "decl";
				attributes = pairsToSet values;
			});

	VersionInfo = sequence [
		Space
		(string "version=")
		(alt
			# single quotes
			(sequence [ (string "'") VersionNumber (string "'") ])
			# double quotes
			(sequence [ (string ''"'') VersionNumber (string ''"'') ]))
	];

	VersionNumber = matching "1\\.[0-9]+";

	Document = bind
		(sequence [
			Prolog # todo: <?xml ... ?><!DOCTYPE ...>
			# no comment before the main element?
			#Element # optional?
			(optional Element) # optional?
			(many Misc)
		])
		(values: pure {
			type = "root";
			children = compact (flatten values);
		});

in {
	# parse node from xml string
	parseXml = runParser (thenSkip Document eof);
}
