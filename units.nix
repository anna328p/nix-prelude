{ self, ... }:

let
	inherit (self)
		pow2
		;

in {
	exports = self: { inherit (self)
		kibi mebi gibi tebi
		kilo mega giga tera
		;
	};

	kibi = pow2 10;
	mebi = pow2 20;
	gibi = pow2 30;
	tebi = pow2 40;

	kilo = 1000;
	mega = 1000 * 1000;
	giga = 1000 * 1000 * 1000;
	tera = 1000 * 1000 * 1000 * 1000;
}
