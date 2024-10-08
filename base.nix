{ ... }:

let
    inherit (builtins)
        foldl'
        isFunction isAttrs
        seq deepSeq
		throw
        ;

in rec {
    exports = self: { inherit (self) 
        id const flip
        compose o compose2 oo
        pipe pipe'
        fix

        force deepForce

        isLambda

        on
        apply2 A2
        and or_ not eq neq
        andA2 orA2
        ;
    };

    # id : a -> a
    id = x: x;

    # const =
    #     sig forall (a: a _- (Fn [Any a])

    # const : a -> (Any -> a)
    const = val: _: val;

    # flip : (a -> b -> c) -> (b -> a -> c)
    flip = f: a: b: f b a;

    # compose : (b -> c) -> (a -> b) -> (a -> c)
    compose = f: g: x: f (g x);
    o = compose;

    # compose2 : (c -> d) -> (a -> b -> c) -> (a -> b -> d)
    oo = o o o;
    compose2 = oo;

    # pipe : a -> [ (a -> b) (b -> c) ... (d -> e) ] -> e 
    pipe = foldl' (flip id);

    # pipe' : [ (a -> b) (b -> c) ... (d -> e) ] -> a -> e 
    pipe' = foldl' (flip compose) id;

    # fix : (a -> a) -> a
    fix = f: let x = f x; in x;

    # side effect: forces evaluation of a
    # force : a -> a
    force = x: seq x x;

    # deepForce : a -> a
    deepForce = x: deepSeq x x;

    # isLambda : Any -> Bool
    isLambda = v:
        isFunction v
            || (isAttrs v
                && isFunction (v.__functor or null)
                && isFunction (v.__functor v));

    # on : (b -> b -> c) -> (a -> b) -> a -> a -> c
    on = a: f: x: y: a (f x) (f y);

    # apply2 : (b -> c -> d) -> (a -> b) -> (a -> c) -> a -> d
    apply2 = a: f: g: x: a (f x) (g x);
    A2 = apply2;

    # and : Bool -> Bool -> Bool
    and = a: b: a && b;

    # `or` is a keyword :(
    # or_ : Bool -> Bool -> Bool
    or_ = a: b: a || b;

    # not : Bool -> Bool
    not = a: !a;

    # eq : a -> b -> Bool
    eq = a: b: a == b;

    # neq : a -> b -> Bool
    neq = a: b: a != b;

    andA2 = apply2 and;
    orA2 = apply2 or_;
}
