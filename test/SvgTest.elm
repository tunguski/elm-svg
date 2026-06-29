module SvgTest exposing (suite)

{-| Tests for elm-svg. The charts are SVG, but all their arithmetic lives in the pure `Scale`
module — domain↔range mapping, nice bounds, ticks and coordinate formatting — so that is what is
checked here, headlessly and exactly.
-}

import Arc
import Curve
import Expect
import Format
import Layout
import Scale
import Stat
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "elm-svg"
        [ convertTests
        , invertTests
        , boundsTests
        , tickTests
        , logTests
        , niceTests
        , arcTests
        , binTests
        , colorTests
        , curveTests
        , statTests
        , numberFormatTests
        , layoutTests
        , formatTests
        ]


within : Float -> Float -> Float -> Expect.Expectation
within tol expected actual =
    if abs (expected - actual) <= tol then
        Expect.pass

    else
        Expect.fail (String.fromFloat actual ++ " ≠ " ++ String.fromFloat expected)


convertTests : Test
convertTests =
    describe "Scale.convert"
        [ test "maps domain start to range start" <|
            \_ -> within 0.001 0 (Scale.convert (Scale.linear ( 0, 10 ) ( 0, 100 )) 0)
        , test "maps domain end to range end" <|
            \_ -> within 0.001 100 (Scale.convert (Scale.linear ( 0, 10 ) ( 0, 100 )) 10)
        , test "maps the midpoint" <|
            \_ -> within 0.001 50 (Scale.convert (Scale.linear ( 0, 10 ) ( 0, 100 )) 5)
        , test "inverts the pixel axis (range start > end)" <|
            \_ -> within 0.001 0 (Scale.convert (Scale.linear ( 0, 10 ) ( 100, 0 )) 10)
        , test "a zero-width domain does not divide by zero" <|
            \_ -> within 0.001 0 (Scale.convert (Scale.linear ( 5, 5 ) ( 0, 100 )) 5)
        ]


invertTests : Test
invertTests =
    describe "Scale.invert"
        [ test "round-trips a value" <|
            \_ ->
                let
                    s =
                        Scale.linear ( 0, 10 ) ( 20, 220 )
                in
                within 0.001 7 (Scale.invert s (Scale.convert s 7))
        ]


boundsTests : Test
boundsTests =
    describe "Scale.niceBounds"
        [ test "always includes a zero baseline" <|
            \_ -> Expect.equal (Scale.niceBounds [ 3, 5, 8 ]) ( 0, 8 )
        , test "extends below zero for negatives" <|
            \_ -> Expect.equal (Scale.niceBounds [ -3, 1, 4 ]) ( -3, 4 )
        , test "never collapses to a point" <|
            \_ -> Expect.equal (Scale.niceBounds [ 5, 5 ]) ( 0, 5 )
        , test "handles an empty list" <|
            \_ -> Expect.equal (Scale.niceBounds []) ( 0, 1 )
        ]


tickTests : Test
tickTests =
    describe "Scale.ticks"
        [ test "produces n+1 evenly spaced ticks" <|
            -- round to ints: the tick values are computed Floats (≠ Float literals under ==).
            \_ -> Expect.equal (List.map round (Scale.ticks 4 ( 0, 100 ))) [ 0, 25, 50, 75, 100 ]
        , test "spans the whole interval" <|
            \_ -> Expect.equal (List.map round (Scale.ticks 5 ( 10, 20 )) |> List.head) (Just 10)
        ]


logTests : Test
logTests =
    describe "Scale.log"
        [ test "maps the low decade to the range start" <|
            \_ -> within 0.001 0 (Scale.convert (Scale.log ( 1, 1000 ) ( 0, 300 )) 1)
        , test "maps the high decade to the range end" <|
            \_ -> within 0.001 300 (Scale.convert (Scale.log ( 1, 1000 ) ( 0, 300 )) 1000)
        , test "puts each decade an equal pixel step apart" <|
            \_ -> within 0.001 100 (Scale.convert (Scale.log ( 1, 1000 ) ( 0, 300 )) 10)
        , test "round-trips through invert" <|
            \_ ->
                let
                    s =
                        Scale.log ( 1, 1000 ) ( 0, 300 )
                in
                within 0.001 50 (Scale.invert s (Scale.convert s 50))
        , test "clamps a non-positive low bound" <|
            \_ -> within 0.001 0 (Scale.convert (Scale.log ( 0, 100 ) ( 0, 200 )) 1.0e-9)
        ]


niceTests : Test
niceTests =
    describe "Scale.niceTicks"
        [ test "rounds a step to the 1·2·5 series" <|
            \_ -> Expect.equal (Scale.niceNum True 1.2) 1
        , test "rounds an awkward step up to 5" <|
            \_ -> Expect.equal (Scale.niceNum True 4.5) 5
        , test "covers the interval with round endpoints" <|
            \_ -> Expect.equal (List.map round (Scale.niceTicks 5 ( 0, 97 ))) [ 0, 20, 40, 60, 80, 100 ]
        , test "snaps the low bound outward" <|
            \_ -> Expect.equal (roundPair (Scale.niceBoundsRounded 5 ( 3, 97 ))) ( 0, 100 )
        , test "spans negatives outward too" <|
            \_ -> Expect.equal (roundPair (Scale.niceBoundsRounded 5 ( -12, 8 ))) ( -15, 10 )
        ]


roundPair : ( Float, Float ) -> ( Int, Int )
roundPair ( a, b ) =
    ( round a, round b )


arcTests : Test
arcTests =
    describe "Arc"
        [ test "angle 0 is twelve o'clock (straight up)" <|
            \_ ->
                let
                    ( x, y ) =
                        Arc.pointOnCircle ( 0, 0 ) 10 0
                in
                Expect.equal ( round x, round y ) ( 0, -10 )
        , test "a quarter turn goes clockwise to the right" <|
            \_ ->
                let
                    ( x, y ) =
                        Arc.pointOnCircle ( 0, 0 ) 10 (pi / 2)
                in
                Expect.equal ( round x, round y ) ( 10, 0 )
        , test "slices split the whole circle by value" <|
            \_ ->
                Expect.equal
                    (List.map (\s -> round (s.fraction * 100)) (Arc.slices [ 1, 1, 2 ]))
                    [ 25, 25, 50 ]
        , test "slices run from 0 to a full turn" <|
            \_ ->
                let
                    last =
                        List.head (List.reverse (Arc.slices [ 3, 5, 2 ]))
                in
                within 0.001 Arc.tau (Maybe.withDefault 0 (Maybe.map .end last))
        , test "an all-zero input falls back to equal slices" <|
            \_ ->
                Expect.equal
                    (List.map (\s -> round (s.fraction * 100)) (Arc.slices [ 0, 0 ]))
                    [ 50, 50 ]
        ]


binTests : Test
binTests =
    describe "Scale.binCounts"
        [ test "counts values into equal-width bins" <|
            \_ -> Expect.equal (Tuple.second (Scale.binCounts 2 [ 0, 1, 2, 3, 4 ])) [ 2, 3 ]
        , test "the maximum lands in the last bin" <|
            \_ -> Expect.equal (Tuple.second (Scale.binCounts 4 [ 0, 10 ])) [ 1, 0, 0, 1 ]
        , test "reports the range it binned over" <|
            \_ -> Expect.equal (Tuple.first (Scale.binCounts 3 [ 2, 5, 8 ])) ( 2, 8 )
        , test "an empty input is all zeros over (0,1)" <|
            \_ -> Expect.equal (Scale.binCounts 2 []) ( ( 0, 1 ), [ 0, 0 ] )
        ]


colorTests : Test
colorTests =
    describe "Scale.interpolateColor"
        [ test "t = 0 is the first colour" <|
            \_ -> Expect.equal (Scale.interpolateColor "#000000" "#ffffff" 0) "#000000"
        , test "t = 1 is the second colour" <|
            \_ -> Expect.equal (Scale.interpolateColor "#000000" "#ffffff" 1) "#ffffff"
        , test "the midpoint is a half mix" <|
            \_ -> Expect.equal (Scale.interpolateColor "#000000" "#ffffff" 0.5) "#808080"
        , test "mixes channels independently" <|
            \_ -> Expect.equal (Scale.interpolateColor "#ff0000" "#0000ff" 0.5) "#800080"
        , test "clamps t past the ends" <|
            \_ -> Expect.equal (Scale.interpolateColor "#102030" "#405060" 2) "#405060"
        ]


curveTests : Test
curveTests =
    describe "Curve.smooth"
        [ test "starts at the first point and ends at the last" <|
            \_ ->
                let
                    out =
                        Curve.catmullRom 4 [ ( 0, 0 ), ( 1, 2 ), ( 2, 1 ), ( 3, 3 ) ]

                    ends =
                        ( Maybe.map roundPair (List.head out)
                        , Maybe.map roundPair (List.head (List.reverse out))
                        )
                in
                Expect.equal ends ( Just ( 0, 0 ), Just ( 3, 3 ) )
        , test "expands the point count by roughly samples per segment" <|
            \_ ->
                -- 4 points → 3 segments × 5 samples + final point = 16
                Expect.equal (List.length (Curve.catmullRom 5 [ ( 0, 0 ), ( 1, 2 ), ( 2, 1 ), ( 3, 3 ) ])) 16
        , test "keeps a straight line straight on an interior segment" <|
            \_ ->
                let
                    -- segment 1 (points 1→2) has symmetric collinear neighbours, so its
                    -- half-way sample (output index 3) must sit exactly on the line at x = 1.5.
                    out =
                        Curve.catmullRom 2 [ ( 0, 0 ), ( 1, 1 ), ( 2, 2 ), ( 3, 3 ), ( 4, 4 ) ]
                in
                within 0.001 1.5 (Maybe.withDefault -99 (List.head (List.drop 3 out) |> Maybe.map Tuple.first))
        , test "leaves fewer than three points untouched" <|
            \_ -> Expect.equal (Curve.smooth [ ( 0, 0 ), ( 1, 1 ) ]) [ ( 0, 0 ), ( 1, 1 ) ]
        ]


statTests : Test
statTests =
    describe "Stat"
        [ test "mean averages the sample" <|
            \_ -> within 0.001 3 (Stat.mean [ 1, 2, 3, 4, 5 ])
        , test "median of an odd sample is the middle value" <|
            \_ -> within 0.001 3 (Stat.median [ 5, 1, 3, 2, 4 ])
        , test "median of an even sample interpolates" <|
            \_ -> within 0.001 2.5 (Stat.median [ 1, 2, 3, 4 ])
        , test "quartiles split the sample" <|
            \_ ->
                let
                    ( q1, q2, q3 ) =
                        Stat.quartiles [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ]
                in
                Expect.equal ( round q1, round q2, round q3 ) ( 3, 5, 7 )
        , test "stdDev of a flat sample is zero" <|
            \_ -> within 0.001 0 (Stat.stdDev [ 4, 4, 4 ])
        , test "stdDev measures spread (population)" <|
            \_ -> within 0.001 2 (Stat.stdDev [ 1, 5 ])
        , test "regression recovers a known line" <|
            \_ ->
                let
                    fit =
                        Stat.linearRegression [ ( 0, 1 ), ( 1, 3 ), ( 2, 5 ), ( 3, 7 ) ]
                in
                Expect.equal ( round fit.slope, round fit.intercept ) ( 2, 1 )
        , test "regression of a vertical spread is flat at mean y" <|
            \_ ->
                let
                    fit =
                        Stat.linearRegression [ ( 5, 2 ), ( 5, 4 ), ( 5, 6 ) ]
                in
                Expect.equal ( fit.slope, round fit.intercept ) ( 0, 4 )
        ]


numberFormatTests : Test
numberFormatTests =
    describe "Format"
        [ test "decimals keeps a fixed number of places" <|
            \_ -> Expect.equal (Format.decimals 1 3.14159) "3.1"
        , test "decimals pads to the requested width" <|
            \_ -> Expect.equal (Format.decimals 2 1.2) "1.20"
        , test "decimals 0 rounds to an integer" <|
            \_ -> Expect.equal (Format.decimals 0 2.6) "3"
        , test "decimals handles negatives" <|
            \_ -> Expect.equal (Format.decimals 1 -2.34) "-2.3"
        , test "percent scales a fraction" <|
            \_ -> Expect.equal (Format.percent 0.64) "64%"
        , test "compact abbreviates thousands" <|
            \_ -> Expect.equal (Format.compact 1200) "1.2k"
        , test "compact abbreviates millions" <|
            \_ -> Expect.equal (Format.compact 3400000) "3.4M"
        , test "compact leaves small numbers whole" <|
            \_ -> Expect.equal (Format.compact 950) "950"
        , test "prefixed adds a symbol" <|
            \_ -> Expect.equal (Format.prefixed "$" (Format.decimals 0) 1000) "$1000"
        , test "suffixed adds a unit" <|
            \_ -> Expect.equal (Format.suffixed " kg" (Format.decimals 1) 2.5) "2.5 kg"
        ]


layoutTests : Test
layoutTests =
    let
        area ( _, _, w, h ) =
            w * h
    in
    describe "Layout.treemap"
        [ test "gives one rectangle per value" <|
            \_ -> Expect.equal (List.length (Layout.treemap ( 0, 0, 100, 100 ) [ 1, 1, 1, 1 ])) 4
        , test "tiles the whole box (areas sum to the box area)" <|
            \_ -> within 0.001 10000 (List.sum (List.map area (Layout.treemap ( 0, 0, 100, 100 ) [ 3, 2, 1, 4 ])))
        , test "areas are proportional to the values" <|
            \_ ->
                Expect.equal
                    (List.map (round << area) (Layout.treemap ( 0, 0, 100, 100 ) [ 3, 1 ]))
                    [ 7500, 2500 ]
        , test "a single value fills the box" <|
            \_ -> Expect.equal (Layout.treemap ( 0, 0, 40, 20 ) [ 5 ]) [ ( 0, 0, 40, 20 ) ]
        , test "an empty list yields no rectangles" <|
            \_ -> Expect.equal (Layout.treemap ( 0, 0, 100, 100 ) []) []
        ]


formatTests : Test
formatTests =
    describe "Scale formatting"
        [ test "integers drop the decimal" <|
            \_ -> Expect.equal (Scale.num 42) "42"
        , test "fractions are trimmed" <|
            \_ -> Expect.equal (Scale.num 3.14159) "3.142"
        , test "a point is x,y" <|
            \_ -> Expect.equal (Scale.point ( 1.5, 2.25 )) "1.5,2.25"
        , test "pointsString joins points" <|
            \_ -> Expect.equal (Scale.pointsString [ ( 0, 0 ), ( 1, 2 ) ]) "0,0 1,2"
        ]
