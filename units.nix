{ ... }:

{
	exports = self: { inherit (self)
		kibi mebi gibi tebi
		kilo mega giga tera
		;
	};

	kibi = 1024;
	mebi = 1024 * 1024;
	gibi = 1024 * 1024 * 1024;
	tebi = 1024 * 1024 * 1024 * 1024;

	kilo = 1000;
	mega = 1000 * 1000;
	giga = 1000 * 1000 * 1000;
	tera = 1000 * 1000 * 1000 * 1000;
}
