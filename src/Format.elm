module Format exposing
    ( decimals, percent, compact
    , prefixed, suffixed
    )

{-| Ready-made number formatters — `Float -> String` functions to hand to `Chart.withFormat` so an
axis reads as money, a percentage, or compact `k`/`M` values. No SVG; pure, so it is unit-tested.

    Chart.bars (Chart.withFormat (Format.prefixed "$" (Format.decimals 0)) cfg) data

@docs decimals, percent, compact
@docs prefixed, suffixed

-}


{-| Fixed number of decimal places, e.g. `decimals 1 3.14159 == "3.1"`. -}
decimals : Int -> Float -> String
decimals n x =
    let
        p =
            10 ^ Basics.max 0 n

        scaled =
            toFloat (round (x * toFloat p)) / toFloat p
    in
    if n <= 0 then
        String.fromInt (round scaled)

    else
        let
            neg =
                scaled < 0

            whole =
                truncate (abs scaled)

            frac =
                round ((abs scaled - toFloat whole) * toFloat p)

            -- a frac that rounded up to a full unit carries into the whole part
            ( whole2, frac2 ) =
                if frac >= p then
                    ( whole + 1, frac - p )

                else
                    ( whole, frac )

            fracStr =
                String.padLeft n '0' (String.fromInt frac2)
        in
        (if neg then
            "-"

         else
            ""
        )
            ++ String.fromInt whole2
            ++ "."
            ++ fracStr


{-| A fraction shown as a percentage, e.g. `percent 0.64 == "64%"`. -}
percent : Float -> String
percent x =
    decimals 0 (x * 100) ++ "%"


{-| A compact magnitude with a `k` / `M` / `B` suffix, e.g. `compact 1200 == "1.2k"`. -}
compact : Float -> String
compact x =
    let
        a =
            abs x

        sign =
            if x < 0 then
                "-"

            else
                ""
    in
    if a >= 1.0e9 then
        sign ++ trim (a / 1.0e9) ++ "B"

    else if a >= 1.0e6 then
        sign ++ trim (a / 1.0e6) ++ "M"

    else if a >= 1.0e3 then
        sign ++ trim (a / 1.0e3) ++ "k"

    else
        sign ++ trim a


trim : Float -> String
trim x =
    -- one decimal, but drop a trailing ".0"
    let
        s =
            decimals 1 x
    in
    if String.endsWith ".0" s then
        String.dropRight 2 s

    else
        s


{-| Wrap a formatter with a leading symbol, e.g. `prefixed "$" (decimals 2)`. -}
prefixed : String -> (Float -> String) -> Float -> String
prefixed sym fmt x =
    sym ++ fmt x


{-| Wrap a formatter with a trailing unit, e.g. `suffixed " kg" (decimals 1)`. -}
suffixed : String -> (Float -> String) -> Float -> String
suffixed unit fmt x =
    fmt x ++ unit
