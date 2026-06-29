module Stat exposing
    ( mean, median, quantile, quartiles, stdDev
    , Line, linearRegression
    )

{-| The small statistics behind box plots, trend lines and the like: summarising a sample and
fitting a line to points. No SVG here — it is just numbers, so it is fully unit-tested and reusable.

@docs mean, median, quantile, quartiles, stdDev
@docs Line, linearRegression

-}


{-| The arithmetic mean (`0` for an empty list). -}
mean : List Float -> Float
mean xs =
    case List.length xs of
        0 ->
            0

        n ->
            List.sum xs / toFloat n


{-| The `p`-quantile (`p` in `0…1`) by linear interpolation between the two nearest ranks of the
sorted sample. `quantile 0.5` is the median; `0` for an empty list.
-}
quantile : Float -> List Float -> Float
quantile p xs =
    case List.sort xs of
        [] ->
            0

        sorted ->
            let
                n =
                    List.length sorted

                pos =
                    clamp 0 1 p * toFloat (n - 1)

                lo =
                    floor pos

                frac =
                    pos - toFloat lo

                a =
                    at lo sorted

                b =
                    at (lo + 1) sorted |> Maybe.withDefault (Maybe.withDefault 0 a)
            in
            Maybe.withDefault 0 a + (b - Maybe.withDefault 0 a) * frac


at : Int -> List Float -> Maybe Float
at i xs =
    List.head (List.drop i xs)


{-| The median — the `0.5` quantile. -}
median : List Float -> Float
median =
    quantile 0.5


{-| The lower quartile, median and upper quartile as `( q1, q2, q3 )`. -}
quartiles : List Float -> ( Float, Float, Float )
quartiles xs =
    ( quantile 0.25 xs, quantile 0.5 xs, quantile 0.75 xs )


{-| The population standard deviation (`0` for an empty list). -}
stdDev : List Float -> Float
stdDev xs =
    case List.length xs of
        0 ->
            0

        n ->
            let
                m =
                    mean xs
            in
            sqrt (List.sum (List.map (\x -> (x - m) ^ 2) xs) / toFloat n)


{-| A fitted line `y = slope · x + intercept`. -}
type alias Line =
    { slope : Float
    , intercept : Float
    }


{-| The ordinary least-squares line through `(x, y)` points. A degenerate input (no spread in x)
yields a flat line at the mean y.
-}
linearRegression : List ( Float, Float ) -> Line
linearRegression pts =
    case List.length pts of
        0 ->
            { slope = 0, intercept = 0 }

        n ->
            let
                nf =
                    toFloat n

                sumX =
                    List.sum (List.map Tuple.first pts)

                sumY =
                    List.sum (List.map Tuple.second pts)

                sumXY =
                    List.sum (List.map (\( x, y ) -> x * y) pts)

                sumXX =
                    List.sum (List.map (\( x, _ ) -> x * x) pts)

                denom =
                    nf * sumXX - sumX * sumX
            in
            if denom == 0 then
                { slope = 0, intercept = sumY / nf }

            else
                let
                    slope =
                        (nf * sumXY - sumX * sumY) / denom
                in
                { slope = slope, intercept = (sumY - slope * sumX) / nf }
