# elm-svg

A small, **dependency-free SVG charting library** in Elm, for the
[elm-lang](https://github.com/tunguski/elm-lang) compiler.

Live demo: **https://tunguski.github.io/elm-svg/**

One call gives you a chart:

```elm
import Chart

Chart.bars Chart.defaults [ ( "Jan", 120 ), ( "Feb", 98 ), ( "Mar", 145 ) ]
Chart.line Chart.defaults temps           -- (label, value) with a zero baseline
Chart.scatter Chart.defaults points       -- raw (x, y)
Chart.multiLine Chart.defaults serieses   -- several named series, palette-coloured
```

Each function returns an `Svg msg` you drop straight into a page. The number-crunching —
mapping a data domain onto a pixel range, choosing bounds and ticks, formatting coordinates —
lives in a separate, fully unit-tested [`Scale`](src/Scale.elm) module.

## Modules

- **`Scale`** — the pure maths: `linear` / `convert` / `invert` scales, `niceBounds`, `ticks`,
  and coordinate formatting (`num` / `point` / `pointsString`). No SVG, so it is exhaustively
  tested.
- **`Chart`** — `bars`, `line`, `scatter`, `multiLine` over plain Elm data, plus the building
  blocks (`frame`, `polylineOf`, `dotsOf`) for bespoke charts.

## Two gotchas it bakes in

This library targets the elm-lang JS backend, and encodes two of its quirks so you don't trip
on them:

- **`Svg.Attributes.class` is unbound**, so SVG nodes can't be styled by CSS class — every colour
  is set **inline** from the [`Config`](src/Chart.elm). Pass colours through the config.
- **A record update on a record alias imported from another module miscompiles** (the un-updated
  fields come back `undefined`). So tweak a `Config` with the provided constructors —
  `Chart.sized w h`, `Chart.colored "#…"` — which do the update *inside* `Chart`, rather than
  `{ Chart.defaults | width = … }` at your own call site.

## Use it in another project

Each elm-lang project is its own repo, so reuse is by **vendoring**: copy `src/Scale.elm` and
`src/Chart.elm` into your project's source path and import `Chart`. (This is how `elm-notebook`
draws its cell charts.)

## Develop

With this repo checked out next to a built [`elm-lang`](https://github.com/tunguski/elm-lang)
(so `../../elm.sh` exists):

```sh
ELM=../../elm.sh ./test.sh     # run the headless Scale test suite
ELM=../../elm.sh ./build.sh    # compile the demo gallery → build/elm-svg.html
```

`.github/workflows/pages.yml` runs the same in CI and deploys to GitHub Pages, gated on the
tests passing.

Part of the [elm-lang](https://github.com/tunguski/elm-lang) ecosystem.
