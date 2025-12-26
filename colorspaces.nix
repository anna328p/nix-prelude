{ self, ... }:

let
	inherit (builtins)
		;

	inherit (self)
		powf
		pow
		matmul
		cbrt
		;
in rec {
	exports = self: { inherit (self)
		;
	};

	# newtype SRGBLinear = SRGBLinear Float
	# newtype SRGBValue = SRGBValue Float

	# srgbTransferEncode : Float -> SRGBLinear -> SRGBValue
	srgbTransferEncode = gamma: x:
		if (x >= 0.0031308) then
			1.055 * (powf x (1.0 / gamma)) - 0.055
		else
			12.92 * x;

	# srgbTransferDecode : Float -> SRGBValue -> SRGBLinear
	srgbTransferDecode = gamma: x:
		if (x >= 0.04045) then
			powf ((x + 0.055) / 1.055) gamma
		else
			x / 12.92;


}
