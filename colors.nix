{ self, ... }:

with self; rec {
    exports = self: { inherit (self)
        prefixHash genDecls genVarDecls byKind;
    };

    prefixAttrs = o mapAttrValues addStrings;
    prefixHash = prefixAttrs "#";

    genDecls = oo concatLines mapSetEntries;

    genVarDecls = genDecls (k: v: "--${k}: ${v} !important;");

    byVariant = variant: light: dark: { inherit light dark; }.${variant};
}
