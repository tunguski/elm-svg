module SvgTest exposing (suite)

{-| Tests for elm-svg. The charts are SVG, but all their arithmetic lives in the pure `Scale`
module — domain↔range mapping, nice bounds, ticks and coordinate formatting — so that is what is
checked here, headlessly and exactly.
-}

import Expect
import Scale
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "elm-svg"
        [ convertTests
        , invertTests
        , boundsTests
        , tickTests
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
