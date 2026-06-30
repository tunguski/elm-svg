module Scale exposing
    ( Scale, linear, log, convert, invert
    , niceBounds, ticks, niceNum, niceTicks, niceBoundsRounded
    , binCounts, interpolateColor, allocate
    , num, point, pointsString
    )

{-| The pure maths behind a chart: mapping a **data domain** onto a **pixel range**, choosing
sensible bounds and tick marks, and formatting coordinates. No SVG here — it is just numbers, so
it is fully unit-tested and reusable by any renderer.

Scales are linear by default; [`log`](#log) builds a base-10 logarithmic scale (same `Scale`
record, so [`convert`](#convert)/[`invert`](#invert) and the charts work unchanged). For axis
ticks, [`ticks`](#ticks) is plain even spacing while [`niceTicks`](#niceTicks) rounds the step to
a 1·2·5 series and snaps the bounds outward, which reads far better on a real axis.

@docs Scale, linear, log, convert, invert
@docs niceBounds, ticks, niceNum, niceTicks, niceBoundsRounded
@docs binCounts, interpolateColor, allocate
@docs num, point, pointsString

-}


{-| A scale from a data interval `(d0, d1)` to a pixel interval `(r0, r1)`. `logBase` is `False`
for a linear scale and `True` for a base-10 log scale (see [`log`](#log)); both share this record
so a renderer never has to special-case which kind it holds.
-}
type alias Scale =
    { d0 : Float
    , d1 : Float
    , r0 : Float
    , r1 : Float
    , logBase : Bool
    }


{-| Build a linear scale. A zero-width domain is nudged to width 1 so nothing divides by zero. -}
linear : ( Float, Float ) -> ( Float, Float ) -> Scale
linear ( d0, d1 ) ( r0, r1 ) =
    { d0 = d0
    , d1 =
        if d1 == d0 then
            d0 + 1

        else
            d1
    , r0 = r0
    , r1 = r1
    , logBase = False
    }


{-| Build a base-10 logarithmic scale. Non-positive domain bounds are clamped up to a tiny positive
value (a log axis has no room for zero or negatives), so equal-spaced *decades* map to equal pixels.
-}
log : ( Float, Float ) -> ( Float, Float ) -> Scale
log ( d0, d1 ) ( r0, r1 ) =
    let
        lo =
            Basics.max 1.0e-9 d0

        hi =
            Basics.max (lo * 10) d1
    in
    { d0 = lo, d1 = hi, r0 = r0, r1 = r1, logBase = True }


lg : Float -> Float
lg v =
    logBase 10 (Basics.max 1.0e-9 v)


{-| Map a value from the data domain to the pixel range. -}
convert : Scale -> Float -> Float
convert s v =
    let
        ( a, b, x ) =
            if s.logBase then
                ( lg s.d0, lg s.d1, lg v )

            else
                ( s.d0, s.d1, v )

        denom =
            if b == a then
                1

            else
                b - a
    in
    s.r0 + (s.r1 - s.r0) * (x - a) / denom


{-| Map a pixel back to a data value (the inverse of [`convert`](#convert)). -}
invert : Scale -> Float -> Float
invert s p =
    let
        frac =
            if s.r1 == s.r0 then
                0

            else
                (p - s.r0) / (s.r1 - s.r0)
    in
    if s.logBase then
        10 ^ (lg s.d0 + frac * (lg s.d1 - lg s.d0))

    else
        s.d0 + (s.d1 - s.d0) * frac


{-| Bounds that make a nice axis for a set of values: always include a zero baseline, and never
collapse to a single point.
-}
niceBounds : List Float -> ( Float, Float )
niceBounds values =
    let
        lo =
            Basics.min 0 (List.minimum values |> Maybe.withDefault 0)

        hi =
            Basics.max 0 (List.maximum values |> Maybe.withDefault 1)
    in
    if hi == lo then
        ( lo, lo + 1 )

    else
        ( lo, hi )


{-| `n + 1` evenly-spaced tick values spanning `(lo, hi)` inclusive. -}
ticks : Int -> ( Float, Float ) -> List Float
ticks n ( lo, hi ) =
    let
        steps =
            Basics.max 1 n
    in
    List.map
        (\i -> lo + (hi - lo) * toFloat i / toFloat steps)
        (List.range 0 steps)


{-| Round a span to a "nice" number — one of `1`, `2`, `5` (or `10`) times a power of ten. With
`round_` true the nearest nice number is chosen (good for a tick *step*); otherwise the nice number
is rounded up to cover the span (good for a total *range*). The textbook axis-labelling helper.
-}
niceNum : Bool -> Float -> Float
niceNum round_ span =
    if span <= 0 then
        1

    else
        let
            exp =
                toFloat (floor (logBase 10 span))

            pow =
                10 ^ exp

            f =
                span / pow

            nf =
                if round_ then
                    if f < 1.5 then
                        1

                    else if f < 3 then
                        2

                    else if f < 7 then
                        5

                    else
                        10

                else if f <= 1 then
                    1

                else if f <= 2 then
                    2

                else if f <= 5 then
                    5

                else
                    10
        in
        nf * pow


{-| Up to `maxTicks` axis values stepped by a nice 1·2·5 amount, snapped *outward* so the whole
`(lo, hi)` interval is covered. Unlike [`ticks`](#ticks) the endpoints are round numbers.
-}
niceTicks : Int -> ( Float, Float ) -> List Float
niceTicks maxTicks ( lo, hi ) =
    let
        range =
            niceNum False (hi - lo)

        step =
            niceNum True (range / toFloat (Basics.max 1 (maxTicks - 1)))

        niceLo =
            step * toFloat (floor (lo / step))

        niceHi =
            step * toFloat (ceiling (hi / step))

        n =
            Basics.max 1 (round ((niceHi - niceLo) / step))
    in
    List.map (\i -> niceLo + step * toFloat i) (List.range 0 n)


{-| The outermost nice bounds [`niceTicks`](#niceTicks) would snap to — a rounded `(lo, hi)` pair
to scale an axis against, so the data sits flush to round gridlines.
-}
niceBoundsRounded : Int -> ( Float, Float ) -> ( Float, Float )
niceBoundsRounded maxTicks bounds =
    let
        ts =
            niceTicks maxTicks bounds

        first =
            List.head ts |> Maybe.withDefault (Tuple.first bounds)

        last =
            List.head (List.reverse ts) |> Maybe.withDefault (Tuple.second bounds)
    in
    ( first, last )


{-| Split `values` into `n` equal-width bins over their min…max range and count how many fall in
each (a value equal to the max lands in the last bin). Returns the `(lo, hi)` range used and the
per-bin counts — the maths behind a histogram. An empty input yields zero counts over `(0, 1)`.
-}
binCounts : Int -> List Float -> ( ( Float, Float ), List Int )
binCounts n values =
    let
        bins =
            Basics.max 1 n

        lo =
            List.minimum values |> Maybe.withDefault 0

        hi =
            List.maximum values |> Maybe.withDefault 1

        ( a, b ) =
            if hi == lo then
                ( lo, lo + 1 )

            else
                ( lo, hi )

        width =
            (b - a) / toFloat bins

        idx v =
            clamp 0 (bins - 1) (floor ((v - a) / width))

        bump i list =
            List.indexedMap
                (\j c ->
                    if j == i then
                        c + 1

                    else
                        c
                )
                list
    in
    ( ( a, b ), List.foldl (\v acc -> bump (idx v) acc) (List.repeat bins 0) values )


{-| Blend two `"#rrggbb"` colours: `t = 0` gives the first, `t = 1` the second, between is a linear
mix of the channels (`t` is clamped). Builds a sequential colour ramp for heatmaps, bubbles, etc.
-}
interpolateColor : String -> String -> Float -> String
interpolateColor c0 c1 t =
    let
        tt =
            clamp 0 1 t

        ( r0, g0, b0 ) =
            hexToRgb c0

        ( r1, g1, b1 ) =
            hexToRgb c1

        mix x y =
            round (toFloat x + (toFloat y - toFloat x) * tt)
    in
    "#" ++ toHex2 (mix r0 r1) ++ toHex2 (mix g0 g1) ++ toHex2 (mix b0 b1)


hexDigits : String
hexDigits =
    "0123456789abcdef"


hexToRgb : String -> ( Int, Int, Int )
hexToRgb s =
    let
        h =
            String.replace "#" "" s

        pair from =
            16 * hexDigit (String.slice from (from + 1) h) + hexDigit (String.slice (from + 1) (from + 2) h)
    in
    ( pair 0, pair 2, pair 4 )


hexDigit : String -> Int
hexDigit ch =
    String.indexes (String.toLower ch) hexDigits |> List.head |> Maybe.withDefault 0


toHex2 : Int -> String
toHex2 n =
    let
        c =
            clamp 0 255 n

        nib d =
            String.slice d (d + 1) hexDigits
    in
    nib (c // 16) ++ nib (modBy 16 c)


{-| Apportion `n` whole units among `weights` in proportion, using the **largest-remainder** method
so the parts sum to *exactly* `n`. Each gets `floor(share)`, then the leftover units go one each to
the largest fractional remainders. The maths behind a waffle chart's 100 cells.
-}
allocate : Int -> List Float -> List Int
allocate n weights =
    let
        total =
            List.sum (List.map (Basics.max 0) weights)
    in
    if total <= 0 || n <= 0 then
        List.map (\_ -> 0) weights

    else
        let
            shares =
                List.map (\w -> Basics.max 0 w / total * toFloat n) weights

            floors =
                List.map floor shares

            leftover =
                n - List.sum floors

            -- indices ranked by descending fractional remainder
            ranked =
                List.indexedMap (\i s -> ( i, s - toFloat (floor s) )) shares
                    |> List.sortBy (\( _, frac ) -> -frac)
                    |> List.take leftover
                    |> List.map Tuple.first
        in
        List.indexedMap
            (\i base ->
                if List.member i ranked then
                    base + 1

                else
                    base
            )
            floors


{-| Format a number compactly: integers without a trailing `.0`, others to a few decimals. -}
num : Float -> String
num n =
    if isNaN n || isInfinite n then
        "0"

    else if toFloat (round n) == n && abs n < 1.0e12 then
        String.fromInt (round n)

    else
        String.fromFloat (toFloat (round (n * 1000)) / 1000)


{-| An `"x,y"` coordinate string for SVG points/paths (rounded to 2 dp). -}
point : ( Float, Float ) -> String
point ( x, y ) =
    round2 x ++ "," ++ round2 y


{-| A space-separated list of `"x,y"` coordinates for a `<polyline>`/`<polygon>` `points`. -}
pointsString : List ( Float, Float ) -> String
pointsString pts =
    String.join " " (List.map point pts)


round2 : Float -> String
round2 f =
    String.fromFloat (toFloat (round (f * 100)) / 100)
