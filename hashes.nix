{ ... }:

let
	inherit (builtins)
		hashString
		;
in {
 	exports = self: { inherit (self)
 		md5Sum
 		sha1Sum
 		sha256Sum
 		sha512Sum
 		;
 	};

	# md5Sum : String -> String
 	md5Sum = hashString "md5";

	# sha1Sum : String -> String
 	sha1Sum = hashString "sha1";

	# sha256Sum : String -> String
 	sha256Sum = hashString "sha256";

	# sha512Sum : String -> String
 	sha512Sum = hashString "sha512";
}
