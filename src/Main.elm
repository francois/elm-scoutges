module Main exposing (..)

import Browser
import Debug
import Element exposing (Element, alignLeft, alignRight, centerX, centerY, column, el, fill, height, padding, px, rgb255, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import Html exposing (Html)
import Html.Events
import Http
import Json.Decode as Decode
import Json.Encode as Encode



---- MODEL ----


type alias Model =
    { email : Maybe String
    , password : Maybe String
    , authenticationState : AuthenticationState
    }


type AuthenticationState
    = Authenticated String
    | Anonymous
    | Authenticating
    | AuthenticationFailure


type alias AuthenticationResponse =
    { token : String
    }


type alias AuthenticationRequest =
    { email : String
    , password : String
    }


init : ( Model, Cmd Msg )
init =
    ( { email = Nothing, password = Nothing, authenticationState = Anonymous }, Cmd.none )



---- UPDATE ----


type Msg
    = SetEmail String
    | SetPassword String
    | Authenticate
    | AuthenticateResult (Result Http.Error AuthenticationResponse)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetPassword str ->
            ( { model | password = Just str }, Cmd.none )

        SetEmail str ->
            ( { model | email = Just str }, Cmd.none )

        Authenticate ->
            case ( model.email, model.password ) of
                ( Just email, Just pass ) ->
                    ( { model | authenticationState = Authenticating }
                    , authenticate (AuthenticationRequest email pass)
                    )

                otherwise ->
                    ( model, Cmd.none )

        AuthenticateResult (Ok resp) ->
            ( { model | authenticationState = Authenticated resp.token }, Cmd.none )

        AuthenticateResult (Err resp) ->
            ( { model | authenticationState = AuthenticationFailure }, Cmd.none )



---- VIEW ----


view : Model -> Html.Html Msg
view model =
    let
        body =
            case model.authenticationState of
                Anonymous ->
                    registerOrSignInFormView

                Authenticated _ ->
                    authenticatedView

                Authenticating ->
                    authenticatingView

                AuthenticationFailure ->
                    registerOrSignInFormView
    in
    Element.layout [ Font.color gray1, Background.color white, centerX, Element.paddingXY 0 320 ] (body model)


authenticatedView : Model -> Element Msg
authenticatedView model =
    el [] (text "Authenticated!")


registerOrSignInFormView : Model -> Element Msg
registerOrSignInFormView model =
    column [ spacing 16, centerX, Background.color gray7, height (fill |> Element.minimum 320 |> Element.maximum 320) ]
        [ el [ width fill, Region.heading 1, Font.size 32, Background.color gray6, Element.paddingXY 32 8 ] (text "Sign in or Register")
        , el [ width (fill |> Element.minimum 400 |> Element.maximum 480) ] (emailPasswordFormView model)
        ]


authenticatingView : Model -> Element Msg
authenticatingView model =
    column [ centerX, Background.color gray7, height (fill |> Element.minimum 320 |> Element.maximum 320) ]
        [ el [ width fill, Region.heading 1, Font.size 32, Background.color gray6, Element.paddingXY 32 8 ] (text "Sign in or Register")
        , el [ height fill, width (fill |> Element.minimum 400 |> Element.maximum 480) ] spinner
        ]


spinner : Element Msg
spinner =
    Element.image [ width (px 64), centerX, centerY ]
        { src = "/images/spinner.gif"
        , description = ""
        }


emailPasswordFormView : Model -> Element Msg
emailPasswordFormView model =
    column [ padding 8, spacing 8, width fill ]
        [ Input.email [ onEnter Authenticate ]
            { onChange = SetEmail
            , text =
                case model.email of
                    Just str ->
                        str

                    Nothing ->
                        ""
            , placeholder = Nothing
            , label = Input.labelAbove [ alignLeft, Element.pointer ] (text "Email")
            }
        , Input.currentPassword [ onEnter Authenticate ]
            { onChange = SetPassword
            , show = False
            , text =
                case model.password of
                    Just str ->
                        str

                    Nothing ->
                        ""
            , placeholder = Nothing
            , label = Input.labelAbove [ alignLeft, Element.pointer ] (text "Password")
            }
        , el [ Element.paddingXY 0 16, width fill ]
            (Input.button [ centerX ]
                { label = el [ Background.color callToActionColor, padding 16, Font.color white ] (text "Sign in or Register")
                , onPress = Just Authenticate
                }
            )
        ]


callToActionColor =
    rgb255 32 32 240


black =
    rgb255 0 0 0


gray0 =
    black


gray1 =
    rgb255 32 32 32


gray2 =
    rgb255 64 64 64


gray3 =
    rgb255 96 96 96


gray4 =
    rgb255 128 128 128


gray5 =
    rgb255 160 160 160


gray6 =
    rgb255 192 192 192


gray7 =
    rgb255 224 224 224


gray8 =
    white


white =
    rgb255 255 255 255


onEnter : msg -> Element.Attribute msg
onEnter msg =
    Element.htmlAttribute
        (Html.Events.on "keyup"
            (Decode.field "key" Decode.string
                |> Decode.andThen
                    (\key ->
                        if key == "Enter" then
                            Decode.succeed msg

                        else
                            Decode.fail "Not the enter key"
                    )
            )
        )



---- JSON Encoders & Decoders ----


authenticationRequestEncoder : AuthenticationRequest -> Encode.Value
authenticationRequestEncoder req =
    Encode.object
        [ ( "email", Encode.string req.email )
        , ( "password", Encode.string req.password )
        ]


authenticationResponseDecoder : Decode.Decoder AuthenticationResponse
authenticationResponseDecoder =
    Decode.map AuthenticationResponse (Decode.field "token" Decode.string)



---- Commands ----


authenticate : AuthenticationRequest -> Cmd Msg
authenticate req =
    Http.post
        { url = "/rpc/authenticate"
        , body = Http.jsonBody (authenticationRequestEncoder req)
        , expect = Http.expectJson AuthenticateResult authenticationResponseDecoder
        }



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }
