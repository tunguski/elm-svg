module Arc exposing
    ( Slice, slices
    , pointOnCircle, wedgePoints, ringPoints
    , tau
    )

{-| The pure maths behind **pie** and **donut** charts: turning a list of values into angular
slices, and sampling those slices into polygon point-lists. No SVG here — like [`Scale`](Scale)
it is just numbers, so it is fully unit-tested.

Angles are radians measured **clockwise from twelve o'clock** (the natural reading order for a pie),
so a slice grows to the right first. The renderer fills the returned points with a `<polyline>`
(which closes itself when given a `fill`), sidestepping the unbound SVG `<path>`/class attributes
in the elm-lang JS backend.

@docs Slice, slices
@docs pointOnCircle, wedgePoints, ringPoints
@docs tau

-}


{-| A full turn in radians (`2π`). -}
tau : Float
tau =
    2 * pi


{-| One slice of a pie: its `value`, its `fraction` of the whole, and the `start`/`end`/`mid`
angles (radians, clockwise from top) it spans.
-}
type alias Slice =
    { value : Float
    , fraction : Float
    , start : Float
    , end : Float
    , mid : Float
    }


{-| Turn a list of (non-negative) values into consecutive slices filling the whole circle. Negative
values are treated as zero; an all-zero input yields equal slices so nothing vanishes.
-}
slices : List Float -> List Slice
slices values =
    let
        safe =
            List.map (Basics.max 0) values

        total =
            List.sum safe

        denom =
            if total <= 0 then
                toFloat (Basics.max 1 (List.length safe))

            else
                total

        unit =
            if total <= 0 then
                1

            else
                0

        step ( v, start ) acc =
            let
                frac =
                    (if total <= 0 then
                        unit

                     else
                        v
                    )
                        / denom

                end =
                    start + frac * tau
            in
            ( { value = v, fraction = frac, start = start, end = end, mid = (start + end) / 2 } :: acc
            , end
            )

        ( built, _ ) =
            List.foldl
                (\v ( accList, cursor ) -> step ( v, cursor ) accList)
                ( [], 0 )
                safe
    in
    List.reverse built


{-| The point on a circle of `radius` about `center` at `angle` radians (clockwise from top). -}
pointOnCircle : ( Float, Float ) -> Float -> Float -> ( Float, Float )
pointOnCircle ( cx, cy ) radius angle =
    ( cx + radius * sin angle, cy - radius * cos angle )


{-| Sample `[start, end]` into evenly spaced angles (always at least the two endpoints), so an arc
reads as a smooth curve once the points are joined.
-}
arcAngles : Float -> Float -> List Float
arcAngles start end =
    let
        steps =
            Basics.max 2 (ceiling (abs (end - start) / 0.18))

        d =
            (end - start) / toFloat steps
    in
    List.map (\i -> start + d * toFloat i) (List.range 0 steps)


{-| Polygon points for a solid pie wedge: the centre, then the outer arc from `start` to `end`. -}
wedgePoints : ( Float, Float ) -> Float -> Float -> Float -> List ( Float, Float )
wedgePoints center radius start end =
    center :: List.map (pointOnCircle center radius) (arcAngles start end)


{-| Polygon points for a donut segment: the outer arc forward, then the inner arc back. -}
ringPoints : ( Float, Float ) -> Float -> Float -> Float -> Float -> List ( Float, Float )
ringPoints center innerR outerR start end =
    List.map (pointOnCircle center outerR) (arcAngles start end)
        ++ List.map (pointOnCircle center innerR) (List.reverse (arcAngles start end))
