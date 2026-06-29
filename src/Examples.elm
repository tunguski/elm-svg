module Examples exposing (view)

{-| The elm-svg **showcase** — a gallery of live charts drawn by the library (bar, line, scatter,
multi-series), each with the one line of code that produced it. A size control scales every chart
at once, to show the charts are resolution-independent (drawn with a `viewBox`).

This is the site's "Examples" landing; the host wires the size state and a "Workspace" link around
it. It is parameterised by the current `size` and the message that sets it, so it stays a pure view.

@docs view

-}

import Chart
import Format
import Html exposing (Html, code, div, h3, p, pre, section, span, text)
import Html.Attributes as HA
import Html.Events as HE


sales : List ( String, Float )
sales =
    [ ( "Jan", 120 ), ( "Feb", 98 ), ( "Mar", 145 ), ( "Apr", 132 ), ( "May", 168 ), ( "Jun", 180 ) ]


temps : List ( String, Float )
temps =
    [ ( "Mon", -3 ), ( "Tue", 1 ), ( "Wed", 4 ), ( "Thu", 2 ), ( "Fri", 7 ), ( "Sat", 9 ), ( "Sun", 5 ) ]


cloud : List ( Float, Float )
cloud =
    [ ( 1, 2 ), ( 2, 3.2 ), ( 3, 2.8 ), ( 4, 5 ), ( 5, 4.4 ), ( 6, 6.1 ), ( 7, 5.5 ), ( 8, 7.8 ), ( 9, 7.2 ), ( 10, 9 ) ]


waves : List ( String, List ( Float, Float ) )
waves =
    [ ( "sin", List.map (\i -> ( toFloat i, sin (toFloat i / 3) * 4 + 5 )) (List.range 0 24) )
    , ( "cos", List.map (\i -> ( toFloat i, cos (toFloat i / 3) * 3 + 5 )) (List.range 0 24) )
    ]


bands : List ( String, List ( Float, Float ) )
bands =
    [ ( "organic", List.map (\i -> ( toFloat i, 3 + sin (toFloat i / 4) * 1.5 )) (List.range 0 12) )
    , ( "paid", List.map (\i -> ( toFloat i, 2 + cos (toFloat i / 5) )) (List.range 0 12) )
    , ( "referral", List.map (\i -> ( toFloat i, 1.2 + sin (toFloat i / 3) * 0.6 )) (List.range 0 12) )
    ]


revenue : List ( String, List ( String, Float ) )
revenue =
    [ ( "Q1", [ ( "Web", 30 ), ( "Mobile", 20 ), ( "Store", 12 ) ] )
    , ( "Q2", [ ( "Web", 36 ), ( "Mobile", 28 ), ( "Store", 14 ) ] )
    , ( "Q3", [ ( "Web", 33 ), ( "Mobile", 35 ), ( "Store", 11 ) ] )
    , ( "Q4", [ ( "Web", 42 ), ( "Mobile", 39 ), ( "Store", 16 ) ] )
    ]


share : List ( String, Float )
share =
    [ ( "Chrome", 64 ), ( "Safari", 19 ), ( "Edge", 9 ), ( "Firefox", 5 ), ( "Other", 3 ) ]


languages : List ( String, Float )
languages =
    [ ( "Rust", 87 ), ( "Elm", 74 ), ( "Go", 69 ), ( "Haskell", 58 ), ( "C", 46 ) ]


planets : List ( Float, Float, Float )
planets =
    -- distance from sun (AU), mean temperature (°C), mass (Earths)
    [ ( 0.39, 167, 0.055 ), ( 0.72, 464, 0.82 ), ( 1.0, 15, 1.0 ), ( 1.52, -65, 0.11 ), ( 5.2, -110, 318 ), ( 9.5, -140, 95 ) ]


scores : List Float
scores =
    [ 52, 61, 58, 67, 70, 72, 75, 74, 78, 80, 81, 83, 85, 84, 86, 88, 90, 91, 77, 69, 73, 79, 82, 87, 65, 71, 76, 84, 89, 92, 68, 74, 80, 85, 63, 77, 81, 88 ]


radarAxes : List String
radarAxes =
    [ "Speed", "Power", "Range", "Defense", "Agility", "Support" ]


squads : List ( String, List Float )
squads =
    [ ( "Red", [ 8, 6, 4, 7, 9, 5 ] ), ( "Blue", [ 5, 9, 7, 6, 4, 8 ] ) ]


samples : List ( String, List Float )
samples =
    [ ( "Class A", [ 62, 65, 68, 70, 72, 75, 78, 80, 85 ] )
    , ( "Class B", [ 55, 60, 63, 66, 70, 73, 77, 82, 90 ] )
    , ( "Class C", [ 70, 72, 74, 75, 77, 79, 80, 82, 84 ] )
    ]


ohlc : List ( String, Float, Float, Float, Float )
ohlc =
    [ ( "Mon", 100, 108, 98, 105 )
    , ( "Tue", 105, 110, 103, 104 )
    , ( "Wed", 104, 112, 102, 111 )
    , ( "Thu", 111, 115, 107, 109 )
    , ( "Fri", 109, 113, 105, 112 )
    ]


heatCols : List String
heatCols =
    [ "Mon", "Tue", "Wed", "Thu", "Fri" ]


heatRows : List String
heatRows =
    [ "9am", "12pm", "3pm", "6pm" ]


heatVals : List (List Float)
heatVals =
    [ [ 2, 5, 4, 6, 8 ]
    , [ 9, 12, 10, 14, 15 ]
    , [ 6, 8, 7, 9, 11 ]
    , [ 3, 4, 6, 5, 7 ]
    ]


trail : List Float
trail =
    [ 3, 4, 3.5, 5, 4.5, 6, 5.5, 7, 6.5, 8, 7.5, 9 ]


cashflow : List ( String, Float )
cashflow =
    [ ( "Start", 50 ), ( "Sales", 80 ), ( "Refund", -20 ), ( "Costs", -35 ), ( "Tax", -12 ) ]


ranks : List ( String, Float, Float )
ranks =
    [ ( "Rust", 70, 87 ), ( "Elm", 60, 74 ), ( "Go", 75, 69 ), ( "Haskell", 50, 58 ), ( "C", 55, 46 ) ]


measured : List ( Float, Float, Float )
measured =
    [ ( 1, 2.1, 0.4 ), ( 2, 3.0, 0.5 ), ( 3, 2.6, 0.3 ), ( 4, 4.2, 0.6 ), ( 5, 4.0, 0.4 ), ( 6, 5.3, 0.5 ) ]


teams : List ( String, Float )
teams =
    [ ( "Engineering", 42 ), ( "Sales", 28 ), ( "Support", 16 ), ( "Design", 10 ), ( "Ops", 8 ), ( "Legal", 4 ) ]


funnelData : List ( String, Float )
funnelData =
    [ ( "Visits", 1000 ), ( "Signups", 620 ), ( "Trials", 380 ), ( "Paid", 145 ), ( "Renewed", 98 ) ]


schedule : List ( String, Float, Float )
schedule =
    [ ( "Design", 0, 3 ), ( "Build", 2, 7 ), ( "Test", 6, 9 ), ( "Docs", 8, 10 ), ( "Launch", 10, 11 ) ]


ranges : List ( String, Float, Float )
ranges =
    [ ( "Jan", 2, 9 ), ( "Feb", 3, 11 ), ( "Mar", 6, 15 ), ( "Apr", 9, 19 ), ( "May", 13, 23 ) ]


defects : List ( String, Float )
defects =
    [ ( "Scratch", 42 ), ( "Dent", 30 ), ( "Crack", 18 ), ( "Stain", 12 ), ( "Chip", 8 ), ( "Other", 5 ) ]


winds : List ( String, Float )
winds =
    [ ( "N", 8 ), ( "NE", 5 ), ( "E", 3 ), ( "SE", 6 ), ( "S", 9 ), ( "SW", 7 ), ( "W", 4 ), ( "NW", 6 ) ]


ages : List ( String, Float, Float )
ages =
    [ ( "0–19", 22, 21 ), ( "20–39", 28, 27 ), ( "40–59", 26, 27 ), ( "60–79", 17, 19 ), ( "80+", 5, 8 ) ]


league : List ( String, List Float )
league =
    [ ( "Lions", [ 10, 14, 12, 18, 22 ] )
    , ( "Bears", [ 12, 11, 15, 14, 16 ] )
    , ( "Hawks", [ 8, 13, 17, 16, 20 ] )
    , ( "Wolves", [ 14, 10, 9, 12, 13 ] )
    ]


{-| The gallery, at the given size, with size buttons that send `onSize`. -}
view : Float -> (Float -> msg) -> Html msg
view size onSize =
    let
        cfg =
            Chart.sized size (size * 0.55)
    in
    section [ HA.class "es-examples" ]
        [ div [ HA.class "es-sizer" ]
            [ span [] [ text "Scale all charts:" ]
            , sizeButton onSize size 300 "S"
            , sizeButton onSize size 380 "M"
            , sizeButton onSize size 460 "L"
            ]
        , section [ HA.class "es-grid" ]
            [ card "Bar chart" "Chart.bars (Chart.withValues True cfg) sales" "Categorical values over gridlines, labelled per bar; a zero baseline is always shown." (Chart.bars (Chart.withValues True cfg) sales)
            , card "Line chart" "Chart.line cfg temps" "A value per category, with markers. Negative values dip below the baseline." (Chart.line cfg temps)
            , card "Area chart" "Chart.area (Chart.withColor \"#0f9d58\" cfg) sales" "A line with the region down to the baseline filled." (Chart.area (Chart.withColor "#0f9d58" cfg) sales)
            , card "Scatter plot" "Chart.scatter cfg cloud" "Raw (x, y) points, each axis scaled to its own data." (Chart.scatter cfg cloud)
            , card "Multi-series" "Chart.multiLine cfg waves" "Several named series, each in a palette colour, with a legend." (Chart.multiLine cfg waves)
            , card "Bump chart" "Chart.bump cfg league" "Each series' rank per period, connected — how an ordering shifts over time." (Chart.bump cfg league)
            , card "Stacked area" "Chart.stackedArea cfg bands" "Named series stacked into translucent filled bands." (Chart.stackedArea cfg bands)
            , card "Streamgraph" "Chart.streamgraph cfg bands" "The same series flowing around a centred baseline." (Chart.streamgraph cfg bands)
            , card "Stacked bars" "Chart.stackedBars cfg revenue" "Each category split into stacked, colour-keyed segments." (Chart.stackedBars cfg revenue)
            , card "Grouped bars" "Chart.groupedBars cfg revenue" "The same data as side-by-side bars per category." (Chart.groupedBars cfg revenue)
            , card "100% stacked" "Chart.percentBars cfg revenue" "Each category normalised to 100% — compares composition, not totals." (Chart.percentBars cfg revenue)
            , card "Pareto" "Chart.pareto cfg defects" "Sorted bars with a cumulative-% line on a right axis — the 80/20 view." (Chart.pareto cfg defects)
            , card "Pie chart" "Chart.pie cfg share" "Slices sized by value, summing to the whole." (Chart.pie cfg share)
            , card "Donut chart" "Chart.donut (Chart.withInner 0.6 cfg) share" "A pie with a hole — set by Chart.withInner." (Chart.donut (Chart.withInner 0.6 cfg) share)
            , card "Funnel" "Chart.funnel cfg funnelData" "Narrowing stages for a conversion flow; hover for share of the first." (Chart.funnel cfg funnelData)
            , card "Polar area" "Chart.rose cfg winds" "Equal-angle slices with radius by value — a Nightingale rose." (Chart.rose cfg winds)
            , card "Radial bars" "Chart.radialBars cfg share" "Concentric arcs, one ring per category, sweep by value." (Chart.radialBars cfg share)
            , card "Horizontal bars" "Chart.hbars cfg languages" "Categories down the left, values across — good for long labels and rankings." (Chart.hbars cfg languages)
            , card "Bubble chart" "Chart.bubble cfg planets" "A third dimension as bubble area, coloured along a sequential ramp. Hover for values." (Chart.bubble cfg planets)
            , card "Histogram" "Chart.histogram cfg scores" "A raw list of numbers binned into a distribution." (Chart.histogram cfg scores)
            , card "Density" "Chart.density cfg scores" "A smooth kernel-density curve — the continuous companion to a histogram." (Chart.density cfg scores)
            , card "Radar chart" "Chart.radar cfg axes squads" "Several series compared across shared axes." (Chart.radar cfg radarAxes squads)
            , card "Smooth line" "Chart.line (Chart.withCurve True cfg) temps" "The same line, smoothed with a Catmull-Rom curve." (Chart.line (Chart.withCurve True cfg) temps)
            , card "Stepped line" "Chart.line (Chart.withStep True cfg) temps" "A stair step — for values that hold then jump." (Chart.line (Chart.withStep True cfg) temps)
            , card "Box plots" "Chart.boxplot cfg samples" "Quartiles, median and whiskers per sample, from the tested Stat module." (Chart.boxplot cfg samples)
            , card "Candlestick" "Chart.candlestick cfg ohlc" "Open/high/low/close — up days green, down days red." (Chart.candlestick cfg ohlc)
            , card "Heatmap" "Chart.heatmap cfg cols rows grid" "A grid shaded along a colour ramp; hover for values." (Chart.heatmap cfg heatCols heatRows heatVals)
            , card "Treemap" "Chart.treemap cfg teams" "Nested rectangles sized by value, tiled by the Layout module." (Chart.treemap cfg teams)
            , card "Gantt" "Chart.gantt cfg schedule" "Task bars spanning their start–end on a shared time axis." (Chart.gantt cfg schedule)
            , card "Trend line" "Chart.scatter (Chart.withTrend True cfg) cloud" "A least-squares regression line over the points." (Chart.scatter (Chart.withTrend True cfg) cloud)
            , card "Error bars" "Chart.scatterErr cfg measured" "Points with a vertical y ± error whisker each." (Chart.scatterErr cfg measured)
            , card "Reference marks" "Chart.bars (Chart.withRefLine 160 \"goal\" …) sales" "A target line and a tolerance band behind the data." (Chart.bars (Chart.withRefLine 160 "goal" (Chart.withRefBand 150 175 "ok" cfg)) sales)
            , card "Sparkline" "Chart.sparkline (Chart.sized 220 52) trail" "A tiny, axis-less line for inline use." (Chart.sparkline (Chart.sized 220 52) trail)
            , card "Waterfall" "Chart.waterfall cfg cashflow" "Floating bars bridge a start value to an end through up/down contributions." (Chart.waterfall cfg cashflow)
            , card "Gauge" "Chart.gauge cfg 0 100 72" "A single headline value as a dial — for KPIs on a dashboard." (Chart.gauge cfg 0 100 72)
            , card "Bullet" "Chart.bullet cfg { value = 72, target = 85, … }" "A compact KPI: measure bar over qualitative bands with a target tick." (Chart.bullet cfg { value = 72, target = 85, max = 100, bands = [ 50, 75 ] })
            , card "Lollipop" "Chart.lollipop cfg sales" "Stems topped with dots — a lighter alternative to bars." (Chart.lollipop cfg sales)
            , card "Slope chart" "Chart.slope cfg \"2019\" \"2024\" ranks" "Value or rank changes between two periods — green up, red down." (Chart.slope cfg "2019" "2024" ranks)
            , card "Dumbbell" "Chart.dumbbell cfg ranges" "A low–high range per category, as two connected dots." (Chart.dumbbell cfg ranges)
            , card "Population pyramid" "Chart.pyramid cfg \"Male\" \"Female\" ages" "Back-to-back bars comparing two groups across categories." (Chart.pyramid cfg "Male" "Female" ages)
            , card "Formatted axis" "Chart.withFormat (Format.prefixed \"$\" …)" "Number formatting on ticks and value labels — money, percent, compact k/M." (Chart.bars (Chart.withFormat (Format.prefixed "$" (Format.decimals 0)) (Chart.withValues True cfg)) sales)
            , card "Titled & dark" "Chart.bars (Chart.withTitle \"Sales\" …) sales" "Chart and axis titles, on the dark theme — Chart.darken keeps the slider size." (Chart.bars (Chart.withTitle "Sales" (Chart.withAxisTitles "month" "" (Chart.darken cfg))) sales)
            ]
        ]


sizeButton : (Float -> msg) -> Float -> Float -> String -> Html msg
sizeButton onSize current s label =
    Html.button
        [ HA.class
            ("es-size"
                ++ (if current == s then
                        " es-size-on"

                    else
                        ""
                   )
            )
        , HE.onClick (onSize s)
        ]
        [ text label ]


card : String -> String -> String -> Html msg -> Html msg
card title snippet note chart =
    div [ HA.class "es-card" ]
        [ h3 [] [ text title ]
        , div [ HA.class "es-chart-box" ] [ chart ]
        , pre [ HA.class "es-code" ] [ code [] [ text snippet ] ]
        , p [ HA.class "es-note" ] [ text note ]
        ]
