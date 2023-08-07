{ L, ... }:

let
    inherit (builtins)
        isAttrs isBool isFloat isFunction
        isInt isList isPath isString 

        all foldl'
        functionArgs attrNames attrValues
        throw
        concatStringsSep toJSON
        addErrorContext
        ;
in with L; rec {
    exports = self: { inherit (self)
        toLuaLiteral
        ;
    };

    indent = "  ";

    # This DSL forms a monad
    # a   = Any  -- Nix objects
    # M a = Lua  -- Literal Lua code

    # verbatim : String -> Lua
    # Takes unwrapped strings and produces wrapped values

    # toLua : Lua -> String
    # Takes wrapped values and unwraps them to a string

    # toLua (verbatim s) = s

    # so toLua is basically half of bind
    # and verbatim is unit
    M = rec {
        # map : (a -> b) -> M a -> M b
        # map : (String -> String) -> Lua -> Lua
        map = f: val: verbatim (f (toLua val));

        # unit : a -> M a
        # unit : a -> Lua
        unit = verbatim;

        pure = unit;
        return = unit;

        # join : M (M a) -> M a
        join = toLua;

        # bind : M a -> (a -> M b) -> (M b)
        # bind : Lua -> (String -> Lua) -> Lua
        bind = obj: f: f (toLua obj);
    };

    # tableRecord : Lua -> Lua -> Lua
    tableRecord = k: v: verbatim "[${toLua k}] = ${toLua v} ";

    commaJoin = concatStringsSep ", ";

    # mkTableLiteral : [Str] -> Str
    mkTableLiteral = fields: let
        fields' = commaJoin (map toLua fields);
    in
        verbatim "{ ${fields'} }";

    # setToLuaTable : Set -> Str
    setToTable = let
        mkEntries = mapSetPairs (uncurry tableRecord);
    in
        o mkTableLiteral mkEntries;

    # listToLuaTable : List -> Str
    listToTable = mkTableLiteral;

    throwBadType = val:
        throw "value ${val} cannot be converted to a Lua literal";

    verbatim = str:
        assert isString str;
        { __luaVerbatim = true; inherit str; };

    __findFile = _: verbatim;

    _Call = target: args: let
        args' = if isAttrs args then [ args ] else args;
        argList = commaJoin (map toLua args');
    in
        assert isList args || isAttrs args;

        verbatim "${toLua target}(${argList})";

    Call = v: _Call (Wrap v);

    CallFrom = val: key: Call (Index val key);

    CallOn = obj: field: let
        fname = "(${toLua obj}):${field}";
    in
        assert isString field;
        _Call (verbatim fname);

    Chain = obj: fields:
        assert isList fields;
        assert all (f: isPair f && isString (fst f)) fields;

        foldl' (o uncurry CallOn) obj fields;

    Require = name: _Call (verbatim "require") [ name ];

    _Index = obj: key:
        verbatim "${toLua obj}[${toLua key}]";

    Index = v: _Index (Wrap v);

    Index' = obj: keys:
        assert isList keys;
        foldl' Index obj keys;

    Chunk = lines: let
        addSemicolons = map (line: "${toLua line};");
    in
        verbatim (concatStringsSep "\n" (addSemicolons lines));

    Paste = lines:
        verbatim (concatStringsSep ";\n" (map toLua lines));

    Code = o toLua Chunk;

    If = cond: response: let
        parseResponseArg = { Then, Else ? null }@arg: arg;

        response' = if isList response
            then { Then = response; Else = null; }
            else parseResponseArg response;

        consequence = response'.Then;
        alternative = response'.Else;

        ifHasElse = v: if alternative != null then v else "";

        res = ''
            if (${toLua cond}) then
                ${toLua (Chunk consequence)}
            ${ifHasElse "else"}
                ${ifHasElse (toLua (Chunk alternative))}
            end
        '';
    in
        assert isList response || isAttrs response;
        assert isList response'.Then;
        assert (response'.Else != null) -> (isList response'.Else);

        verbatim res;

    fnArgNames = fn: let
        args = functionArgs fn;
        argNames = attrNames args;
        isVariadic = hasEllipsis fn;

        res = argNames ++ (optional isVariadic "...");
    in
        assert isFunction fn;
        assert all (andA2 isBool not) (attrValues args);
        assert isBool isVariadic;
        res;

    substituteArgs = fn: args: let
        placeholders = genSet verbatim args;
    in
        fn placeholders;

    Function = fn: let
        args = fnArgNames fn;
        body = substituteArgs fn args;
        argList = commaJoin args;
    in
        assert isFunction fn;

        verbatim ''
            function(${argList})
                ${toLua (Chunk body)}
            end
        '';

    Return = args:
        assert isList args;
        verbatim "return ${commaJoin (map toLua args)}";

    ReturnOne = arg: Return [ arg ];

    Wrap = arg: verbatim "( ${toLua arg} )";

    ForEach = iter: fn: let
        bindNames = names: f: let
            name = lambdaArgName f;
            name' = verbatim name;
        in
            if isFunction f then
                assert name != null;
                bindNames (names ++ [name]) (f name')
            else
                { inherit names; body = f; };

        inherit (bindNames [] fn) names body;
        argList = commaJoin names;
    in
        assert isFunction fn;
        assert !(hasFormals fn);
        
        verbatim ''
            for ${argList} in ${toLua iter} do
                ${toLua (Chunk body)}
            end
        '';

    Pairs = t: Call (verbatim "pairs") [ t ];
    IPairs = t: Call (verbatim "ipairs") [ t ];

    SetLocal = name: value:
        verbatim "local ${toLua name} = (${toLua value})";

    Set = name: value: verbatim "${toLua name} = (${toLua value})";


    PrefixOp = op: val: verbatim "(${op}(${toLua val}))";

    BinOp = op: a: b: verbatim "((${toLua a}) ${op} (${toLua b}))";

    Count = PrefixOp "#";
    Neg = PrefixOp "-";

    Lt = BinOp "<";
    Gt = BinOp ">";
    Le = BinOp "<=";
    Ge = BinOp ">=";

    Eq = BinOp "==";
    Ne = BinOp "~=";

    Add = BinOp "+";
    Sub = BinOp "-";
    Mul = BinOp "*";
    Div = BinOp "/";
    Exp = BinOp "^";

    Cat = BinOp "..";

    And = BinOp "and";
    Or = BinOp "or";
    Not = PrefixOp "not";

    ListOp = op: let
        fn = concatMapStringsSep
            " ${op} "
            (item: "(${toLua item})");
    in
        list: verbatim (fn list);

    And' = ListOp "and";
    Or' = ListOp "or";

    toLiteral = val: let
        isJSONLike = v:
            isBool v || isInt v || isFloat v
                || isString v || isPath v;
    in
        if val == null then
            verbatim "nil"
        else if isJSONLike val then
            verbatim (toJSON val)
        else if isAttrs val then
            setToTable val
        else if isList val then
            listToTable val
        else if isFunction val then
            throwBadType "<function>"
        else
            throwBadType (toString val);

    # toLua : Any -> Str
    toLua = val: let
        isLuaVerbatim = v: (v.__luaVerbatim or false);
    in
        if isLuaVerbatim val
            then val.str
            else toLua (toLiteral val);

    toLuaLiteral = toLua;
}