{ ... }:

{
	exports = self: { inherit (self) ; };

	it = what: result:
		{
			inherit what result;
		};
}
