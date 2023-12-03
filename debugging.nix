{ self, ... }:

let
	inherit (builtins)
		trace
		;
	
	inherit (self)
		force
		deepForce
		;

in rec {
	exports = self: { inherit (self) 
		pp ppS ppDS ppF ppDF
		;
	};

	pp = x: trace x x;
	ppS = x: trace (force x) x;
	ppDS = x: trace (deepForce x) x;
	ppF = x: pp (force x);
	ppDF = x: pp (deepForce x);
}
