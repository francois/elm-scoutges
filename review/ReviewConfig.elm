module ReviewConfig exposing (config)

import NoInvalidRGBValues
import NoLongImportLines
import NoUnused.CustomTypeConstructors
import NoUnused.Variables
import Review.Rule exposing (Rule)


config : List Rule
config =
    [ NoInvalidRGBValues.rule
    , NoUnused.CustomTypeConstructors.rule
    , NoUnused.Variables.rule
    , NoLongImportLines.rule
    ]
