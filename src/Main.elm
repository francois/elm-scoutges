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
    , authenticationUiState : AuthenticationUIState
    , authMethod : AuthMethod
    }


type AuthenticationUIState
    = Authenticated String
    | Anonymous
    | Authenticating
    | AuthenticationFailure


type AuthMethod
    = Register
    | SignIn


type alias RegistrationResponse =
    { token : String
    }


type alias RegistrationRequest =
    { email : String
    , password : String
    }


type alias SignInResponse =
    { token : String
    }


type alias AuthenticationRequest =
    { email : String
    , password : String
    }


init : ( Model, Cmd Msg )
init =
    ( { email = Nothing, password = Nothing, authenticationUiState = Anonymous, authMethod = SignIn }, Cmd.none )



---- UPDATE ----


type Msg
    = SetEmail String
    | SetPassword String
    | TryAuthenticate
    | TryRegister
    | SignInResult (Result Http.Error SignInResponse)
    | RegisterResult (Result Http.Error RegistrationResponse)
    | ChangeAuthMethod AuthMethod


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetPassword str ->
            ( { model | password = Just str }, Cmd.none )

        SetEmail str ->
            ( { model | email = Just str }, Cmd.none )

        TryAuthenticate ->
            case ( model.email, model.password ) of
                ( Just email, Just pass ) ->
                    ( { model | authenticationUiState = Authenticating }
                    , authenticate (AuthenticationRequest email pass)
                    )

                otherwise ->
                    ( model, Cmd.none )

        TryRegister ->
            case ( model.email, model.password ) of
                ( Just email, Just pass ) ->
                    ( { model | authenticationUiState = Authenticating }
                    , register (RegistrationRequest email pass)
                    )

                otherwise ->
                    ( model, Cmd.none )

        SignInResult (Ok resp) ->
            ( { model | authenticationUiState = Authenticated resp.token }, Cmd.none )

        SignInResult (Err resp) ->
            ( { model | authenticationUiState = AuthenticationFailure }, Cmd.none )

        RegisterResult (Ok resp) ->
            Debug.log "register ok"
                ( { model | authenticationUiState = Authenticated resp.token }, Cmd.none )

        RegisterResult (Err resp) ->
            Debug.log "register err"
                ( { model | authenticationUiState = AuthenticationFailure }, Cmd.none )

        ChangeAuthMethod authMethod ->
            ( { model | authMethod = authMethod }, Cmd.none )



---- VIEW ----


view : Model -> Html.Html Msg
view model =
    let
        body =
            case model.authenticationUiState of
                Anonymous ->
                    registerOrSignInFormView

                Authenticated _ ->
                    authenticatedView

                Authenticating ->
                    authenticatingView

                AuthenticationFailure ->
                    registerOrSignInFormView
    in
    Element.layout [ Font.color gray1, Background.color white, centerX ] (body model)


authenticatedView : Model -> Element Msg
authenticatedView model =
    el [ centerY, centerX ] (text "Authenticated!")


registerOrSignInFormView : Model -> Element Msg
registerOrSignInFormView model =
    column [ spacing 16, centerY, centerX, Background.color gray7, height (fill |> Element.minimum 352 |> Element.maximum 352) ]
        [ signInOrAuthenticateTabView model
        , el [ width (fill |> Element.minimum 400 |> Element.maximum 480) ] (emailPasswordFormView model)
        ]


authenticatingView : Model -> Element Msg
authenticatingView model =
    column [ centerY, centerX, Background.color gray7, height (fill |> Element.minimum 352 |> Element.maximum 352) ]
        [ signInOrAuthenticateTabView model
        , el [ height fill, width (fill |> Element.minimum 400 |> Element.maximum 480) ] spinner
        ]


signInOrAuthenticateTabView : Model -> Element Msg
signInOrAuthenticateTabView model =
    let
        ( bgCol1, bgCol2 ) =
            case model.authMethod of
                Register ->
                    ( gray6, gray7 )

                SignIn ->
                    ( gray7, gray6 )
    in
    row [ width fill, Region.heading 1, Font.size 32, Background.color gray6 ]
        [ el [ padding 8, width (Element.fillPortion 1), Background.color bgCol1 ]
            (Input.button [ centerX, width fill, height fill ]
                { onPress = Just (ChangeAuthMethod SignIn)
                , label = text "Sign In"
                }
            )
        , el [ padding 8, width (Element.fillPortion 1), Background.color bgCol2 ]
            (Input.button [ centerX, width fill, height fill ]
                { onPress = Just (ChangeAuthMethod Register)
                , label = text "Register"
                }
            )
        ]


spinner : Element Msg
spinner =
    Element.image [ width (px 64), centerX, centerY ]
        { src = "/images/spinner.gif"
        , description = ""
        }


emailPasswordFormView : Model -> Element Msg
emailPasswordFormView model =
    let
        authenticationMessage =
            case model.authenticationUiState of
                AuthenticationFailure ->
                    el [ centerX, Font.color (rgb255 255 0 0) ] (text "Invalid username or password")

                otherwise ->
                    el [] (text "")

        ( buttonLabel, msg ) =
            case model.authMethod of
                Register ->
                    ( "Register", TryRegister )

                SignIn ->
                    ( "Sign In", TryAuthenticate )
    in
    column [ padding 8, spacing 8, width fill ]
        [ Input.email [ onEnter msg ]
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
        , Input.currentPassword [ onEnter msg ]
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
        , authenticationMessage
        , el [ Element.paddingXY 0 16, width fill ]
            (Input.button [ centerX ]
                { label =
                    el
                        [ Background.color callToActionColor
                        , padding 16
                        , Font.color white
                        , width (fill |> Element.minimum 240 |> Element.maximum 240)
                        ]
                        (text buttonLabel)
                , onPress = Just msg
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


authenticationResponseDecoder : Decode.Decoder SignInResponse
authenticationResponseDecoder =
    Decode.map SignInResponse (Decode.field "token" Decode.string)


registrationRequestEncoder : RegistrationRequest -> Encode.Value
registrationRequestEncoder req =
    Encode.object
        [ ( "email", Encode.string req.email )
        , ( "password", Encode.string req.password )
        ]


registrationResponseDecoder : Decode.Decoder RegistrationResponse
registrationResponseDecoder =
    Decode.map RegistrationResponse (Decode.field "token" Decode.string)



---- Commands ----


register : RegistrationRequest -> Cmd Msg
register req =
    Http.post
        { url = "/api/rpc/register"
        , body = Http.jsonBody (registrationRequestEncoder req)
        , expect = Http.expectJson RegisterResult registrationResponseDecoder
        }


authenticate : AuthenticationRequest -> Cmd Msg
authenticate req =
    Http.post
        { url = "/api/rpc/sign_in"
        , body = Http.jsonBody (authenticationRequestEncoder req)
        , expect = Http.expectJson SignInResult authenticationResponseDecoder
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
