module Colors exposing (..)

import Element exposing (Color, Element, centerX, centerY, height, px, rgb255, width)


callToActionTextColor : Color
callToActionTextColor =
    white


callToActionBackgroundColor : Color
callToActionBackgroundColor =
    rgb255 32 32 240


black : Color
black =
    rgb255 0 0 0


gray0 : Color
gray0 =
    black


gray1 : Color
gray1 =
    rgb255 32 32 32


gray2 : Color
gray2 =
    rgb255 64 64 64


gray3 : Color
gray3 =
    rgb255 96 96 96


gray4 : Color
gray4 =
    rgb255 128 128 128


gray5 : Color
gray5 =
    rgb255 160 160 160


gray6 : Color
gray6 =
    rgb255 192 192 192


gray7 : Color
gray7 =
    rgb255 224 224 224


gray8 : Color
gray8 =
    white


white : Color
white =
    rgb255 255 255 255


errorBackgroundColor : Color
errorBackgroundColor =
    gray7


errorTextColor : Color
errorTextColor =
    rgb255 240 16 16


spinner : Element msg
spinner =
    Element.image [ width (px 64), centerX, centerY ]
        { src = "/images/spinner.gif"
        , description = ""
        }
