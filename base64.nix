{ self, ... }:

with self; let
    inherit (builtins)
        isString stringLength substring
        foldl'
        genList length elemAt;
in rec {
    exports = self: { inherit (self)
        toBase64;
    };

    # b64Array : [Str]
    b64Array = [
        "A" "B" "C" "D" "E" "F" "G" "H"
        "I" "J" "K" "L" "M" "N" "O" "P"
        "Q" "R" "S" "T" "U" "V" "W" "X"
        "Y" "Z" "a" "b" "c" "d" "e" "f"
        "g" "h" "i" "j" "k" "l" "m" "n"
        "o" "p" "q" "r" "s" "t" "u" "v"
        "w" "x" "y" "z" "0" "1" "2" "3"
        "4" "5" "6" "7" "8" "9" "+" "/"
    ];

    # getNSlice : Int -> [a] -> Int -> [a]
    getNSlice = size: list: n: sublist (n * size) size list;

    # toBase64 : Str -> Str
    toBase64 = str: let
        # len : Int
        len = stringLength str;
        # nFullSlices : Int
        nFullSlices = len / 3;
        # remainder : Int
        remainder = modulo len 3;

        # bytes : [Int]
        bytes = mapStringChars charToInt str;
        # tripletAt : Int -> [Int]
        tripletAt = getNSlice 3 bytes;

        # resInit' : [Str]
        resInit' = genList (o convertTriplet tripletAt) nFullSlices;
        # resInit : Str
        resInit = concatStrings resInit';

        # lastSlice : [Int]
        lastSlice = tripletAt nFullSlices;
        # resLast : Str
        resLast = convertLastSlice lastSlice;
    in
        assert isString str;

        if remainder == 0
            then resInit
            else resInit + resLast;

    # intSextets : Int -> [Int]
    intSextets = i: let
        # divMod64 : Int -> Int
        divMod64 = j: modulo (i / j) 64;

        pow3 = 64 * 64 * 64;
        pow2 = 64 * 64;
        pow1 = 64;
        pow0 = 1;
    in [
        (divMod64 pow3)
        (divMod64 pow2)
        (divMod64 pow1)
        (divMod64 pow0)
    ];

    # sliceToInt : [Int] -> Int
    sliceToInt = foldl' (acc: val: acc * 256 + val) 0;

    # convertTripletInt : Int -> Str
    convertTripletInt = sliceInt:
        concatMapStrings (elemAt b64Array) (intSextets sliceInt);

    # convertTriplet : [Int] -> Str
    convertTriplet = o convertTripletInt sliceToInt;

    convertLastSlice = slice: let
        # len : Int
        len = length slice;
        # sliceAsInt : Int
        sliceAsInt = sliceToInt slice;
    in
        assert len == 1 || len == 2;

        # replace extraneous zero bytes at the end with padding
        if len == 1 then
            let
                int' = sliceAsInt * 256 * 256;
                b64' = convertTripletInt int';
            in
                (substring 0 2 b64') + "=="
        else /* len == 2 */
            let
                int' = sliceAsInt * 256;
                b64' = convertTripletInt int';
            in
                (substring 0 3 b64') + "=";
}
