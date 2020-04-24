module Main exposing (main)

import Base64
import Browser
import Browser.Navigation as Nav
import Colors exposing (..)
import Debug
import Element exposing (Color, Element, centerX, centerY, column, el, fill, height, link, padding, px, rgb255, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import Html.Events
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Url exposing (Url)
import Url.Builder as Builder
import Url.Parser as Parser



---- MODEL ----


type alias Flags =
    { now : Int, token : Maybe String }


type Token
    = Token String


type Request a
    = NotLoaded
    | Loading
    | Loaded a
    | Failure Http.Error


type alias Model =
    { key : Nav.Key
    , token : Maybe Token
    , submodel : Submodel
    }


type Submodel
    = SignIn String String (Request Token)
    | Dashboard
    | NotFound Token


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( { key = key, token = Nothing, submodel = SignIn "" "" NotLoaded }, Cmd.none )



---- UPDATE ----


type Msg
    = FillInEmail String
    | FillInPassword String
    | SubmitSignIn String String
    | SignInResponseReceived (Result Http.Error Token)
    | UrlChanged Url
    | LinkClicked Browser.UrlRequest


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.submodel ) of
        ( FillInEmail str, SignIn _ password tokenRequest ) ->
            ( { model | submodel = SignIn str password tokenRequest }, Cmd.none )

        ( FillInPassword str, SignIn email _ tokenRequest ) ->
            ( { model | submodel = SignIn email str tokenRequest }, Cmd.none )

        ( SubmitSignIn email password, SignIn _ _ _ ) ->
            ( { model | submodel = SignIn email password Loading }, submitSignIn email password )

        ( SignInResponseReceived (Ok token), SignIn _ _ _ ) ->
            ( { model | submodel = Dashboard, token = Just token }, Nav.pushUrl model.key "/dashboard" )

        ( SignInResponseReceived (Err err), SignIn email password _ ) ->
            ( { model | submodel = SignIn email password (Failure err) }, Cmd.none )

        _ ->
            ( model, Cmd.none )



---- VIEW ----


view : Model -> Browser.Document Msg
view model =
    { title = "scoutges"
    , body = [ Element.layout [ width fill, centerX ] (viewBody model) ]
    }


viewBody : Model -> Element Msg
viewBody model =
    Element.column [ width fill, spacing 8 ]
        [ viewNavbar model
        , viewSubmodel model
        ]


viewNavbar : Model -> Element Msg
viewNavbar model =
    let
        elems =
            case model.token of
                Nothing ->
                    []

                _ ->
                    [ Element.link [ Element.alignLeft, padding 4 ] { label = text "Dashboard", url = "/dashboard" }
                    , Element.link [ Element.alignLeft, padding 4 ] { label = text "Parties", url = "/parties" }
                    , Element.link [ Element.alignLeft, padding 4 ] { label = text "Users", url = "/users" }
                    , Element.link [ Element.alignRight, padding 4 ] { label = text "Account", url = "/account" }
                    ]
    in
    Element.row [ width fill, height (px 40), padding 4, Background.color gray7, Font.color gray2 ]
        [ Element.link [ Element.alignLeft, padding 4 ] { label = text "SCOUTGES", url = "/" } ]


viewSubmodel : Model -> Element Msg
viewSubmodel model =
    case model.submodel of
        SignIn email password tokenRequest ->
            viewSignIn model.key email password tokenRequest

        _ ->
            el [] (text "not handled yet")


viewSignIn : Nav.Key -> String -> String -> Request Token -> Element Msg
viewSignIn key email password tokenRequest =
    let
        contents =
            case tokenRequest of
                Loading ->
                    [ el [ width fill, height fill ] Colors.spinner ]

                Failure (Http.BadUrl str) ->
                    signInForm email password (Just ("Bad url: " ++ str))

                Failure Http.NetworkError ->
                    signInForm email password (Just "Network error")

                Failure Http.Timeout ->
                    signInForm email password (Just "Timed out")

                Failure (Http.BadStatus code) ->
                    signInForm email password (Just ("Status " ++ String.fromInt code))

                Failure (Http.BadBody str) ->
                    signInForm email password (Just ("Bad body: " ++ str))

                NotLoaded ->
                    signInForm email password Nothing

                Loaded _ ->
                    signInForm email password Nothing
    in
    Element.column [ centerX, centerY, spacing 8, width (px 400), height (px 376), Background.color gray7 ]
        [ viewTabHeaders "Sign In" [ ( "Sign In", "/sign-in" ), ( "Register", "/register" ) ]
        , Element.column [ width fill, spacing 16, padding 8 ] contents
        ]


signInForm : String -> String -> Maybe String -> List (Element Msg)
signInForm email password reason =
    let
        failedMessage =
            case reason of
                Nothing ->
                    el [] (text "")

                Just str ->
                    el [ Background.color errorBackgroundColor, Font.color errorTextColor, centerX, padding 8, width fill ] (text ("Invalid email or password. " ++ str))
    in
    [ Input.email [ onEnter (SubmitSignIn email password) ]
        { onChange = FillInEmail
        , text = email
        , placeholder = Nothing
        , label = Input.labelAbove [ Element.alignLeft, Element.pointer ] (text "Email")
        }
    , Input.currentPassword [ onEnter (SubmitSignIn email password) ]
        { onChange = FillInPassword
        , text = password
        , placeholder = Nothing
        , show = False
        , label = Input.labelAbove [ Element.alignLeft, Element.pointer ] (text "Password")
        }
    , failedMessage
    , Input.button [ centerX, onEnter (SubmitSignIn email password) ]
        { onPress = Just (SubmitSignIn email password)
        , label = el [ Background.color callToActionBackgroundColor, Font.color callToActionTextColor, padding 16 ] (text "Sign In Now")
        }
    ]


viewTabHeaders : String -> List ( String, String ) -> Element Msg
viewTabHeaders selected headers =
    Element.row [ width fill ] (List.map (viewTabHeader selected) headers)


viewTabHeader : String -> ( String, String ) -> Element Msg
viewTabHeader selected ( label, url ) =
    let
        ( bg, fg ) =
            if selected == label then
                ( gray7, gray1 )

            else
                ( gray3, gray7 )
    in
    Element.link [ width fill, padding 8, Background.color bg, Font.color fg ] { label = text label, url = url }



---- SUBSCRIPTIONS ----


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



---- ROUTING ----


type Route
    = SignInPage


routeParser : Parser.Parser (Route -> a) a
routeParser =
    Parser.oneOf [ Parser.map SignInPage (Parser.s "sign-in") ]



---- UTILITIES ----


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



---- HTTP REQUESTS ----


signInEncoder : String -> String -> Encode.Value
signInEncoder email password =
    Encode.object
        [ ( "email", Encode.string email )
        , ( "password", Encode.string password )
        ]


signInResponseDecoder : Decode.Decoder Token
signInResponseDecoder =
    Decode.map Token (Decode.field "token" Decode.string)


submitSignIn : String -> String -> Cmd Msg
submitSignIn email password =
    Http.post
        { url = "/api/rpc/sign_in"
        , body = Http.jsonBody (signInEncoder email password)
        , expect = Http.expectJson SignInResponseReceived signInResponseDecoder
        }



---- MAIN ----


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }
