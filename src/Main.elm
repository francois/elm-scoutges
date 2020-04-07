module Main exposing (..)

import Browser
import Debug
import Element exposing (Element, alignLeft, alignRight, alignTop, centerX, centerY, column, el, fill, height, padding, px, rgb255, row, spacing, text, width)
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
    { formState : FormState
    , authenticationState : AuthenticationState
    }


type alias JwtToken =
    String


type AuthenticationState
    = Unknown
    | InProgress
    | Failed
    | Authenticated JwtToken


type FormState
    = FillingRegistrationForm RegistrationRequest
    | FillingSignInForm SignInRequest


type alias RegistrationResponse =
    { token : String
    }


type alias RegistrationRequest =
    { email : String
    , password : String
    , name : String
    , groupName : String
    , phone : String
    }


type alias SignInResponse =
    { token : String
    }


type alias SignInRequest =
    { email : String
    , password : String
    }


init : ( Model, Cmd Msg )
init =
    ( { formState = FillingSignInForm newSignInRequest, authenticationState = Unknown }, Cmd.none )


newSignInRequest : SignInRequest
newSignInRequest =
    { email = "", password = "" }


newRegistrationRequest : RegistrationRequest
newRegistrationRequest =
    { email = "", password = "", groupName = "", name = "", phone = "" }



---- UPDATE ----


type Msg
    = SetEmail String
    | SetPassword String
    | SetName String
    | SetGroupName String
    | SetPhone String
    | RunSignIn SignInRequest
    | RunRegister RegistrationRequest
    | SignInResult (Result Http.Error SignInResponse)
    | RegisterResult (Result Http.Error RegistrationResponse)
    | ChangeFormState FormState


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetPassword str ->
            case model.formState of
                FillingSignInForm req ->
                    let
                        newReq =
                            { req | password = str }
                    in
                    ( { model | formState = FillingSignInForm newReq }, Cmd.none )

                FillingRegistrationForm req ->
                    let
                        newReq =
                            { req | password = str }
                    in
                    ( { model | formState = FillingRegistrationForm newReq }, Cmd.none )

        SetEmail str ->
            case model.formState of
                FillingSignInForm req ->
                    let
                        newReq =
                            { req | email = str }
                    in
                    ( { model | formState = FillingSignInForm newReq }, Cmd.none )

                FillingRegistrationForm req ->
                    let
                        newReq =
                            { req | email = str }
                    in
                    ( { model | formState = FillingRegistrationForm newReq }, Cmd.none )

        SetName str ->
            case model.formState of
                FillingRegistrationForm req ->
                    let
                        newReq =
                            { req | name = str }
                    in
                    ( { model | formState = FillingRegistrationForm newReq }, Cmd.none )

                otherwise ->
                    ( model, Cmd.none )

        SetPhone str ->
            case model.formState of
                FillingRegistrationForm req ->
                    let
                        newReq =
                            { req | phone = str }
                    in
                    ( { model | formState = FillingRegistrationForm newReq }, Cmd.none )

                otherwise ->
                    ( model, Cmd.none )

        SetGroupName str ->
            case model.formState of
                FillingRegistrationForm req ->
                    let
                        newReq =
                            { req | groupName = str }
                    in
                    ( { model | formState = FillingRegistrationForm newReq }, Cmd.none )

                otherwise ->
                    ( model, Cmd.none )

        RunSignIn req ->
            ( { model | authenticationState = InProgress }, signIn req )

        RunRegister req ->
            ( { model | authenticationState = InProgress }, register req )

        SignInResult (Ok resp) ->
            ( { model | authenticationState = Authenticated resp.token }, Cmd.none )

        SignInResult (Err resp) ->
            ( { model | authenticationState = Failed }, Cmd.none )

        RegisterResult (Ok resp) ->
            ( { model | authenticationState = Authenticated resp.token }, Cmd.none )

        RegisterResult (Err resp) ->
            ( { model | authenticationState = Failed }, Cmd.none )

        ChangeFormState newState ->
            ( { model | formState = newState, authenticationState = Unknown }, Cmd.none )



---- VIEW ----


view : Model -> Html.Html Msg
view model =
    let
        failed =
            case model.authenticationState of
                Failed ->
                    True

                otherwise ->
                    False

        heightPx =
            case model.formState of
                FillingRegistrationForm _ ->
                    576

                FillingSignInForm _ ->
                    352

        body =
            case model.authenticationState of
                InProgress ->
                    column [ centerY, centerX, Background.color gray7, height (fill |> Element.minimum 352 |> Element.maximum 352) ]
                        [ signInOrAuthenticateTabView model
                        , el [ height fill, width (fill |> Element.minimum 400 |> Element.maximum 480) ] spinner
                        ]

                Authenticated _ ->
                    authenticatedView model

                otherwise ->
                    let
                        form =
                            case model.formState of
                                FillingRegistrationForm req ->
                                    registerFormView req failed

                                FillingSignInForm req ->
                                    signInFormView req failed
                    in
                    column [ spacing 16, centerY, centerX, Background.color gray7, height (Element.px heightPx) ]
                        [ signInOrAuthenticateTabView model
                        , el [ width (fill |> Element.minimum 400 |> Element.maximum 480) ] form
                        ]
    in
    Element.layout [ Font.color gray1, Background.color white, centerX ] body


authenticatedView : Model -> Element Msg
authenticatedView model =
    column [ spacing 16, width fill ]
        [ el [ padding 8, width fill, Background.color gray7, Font.color gray2 ] (navbarView model)
        , column [ padding 8, width fill, Font.alignLeft ]
            [ el [ Font.size 32, Font.bold, Region.heading 1 ] (text "Welcome to Scoutges")
            , el [ Element.paddingXY 0 8 ] (authBody model)
            ]
        ]


navbarView : Model -> Element Msg
navbarView model =
    row [ Element.alignTop, width fill, Region.navigation ]
        [ row [ width fill, spacing 8 ]
            [ el [ padding 8, Element.alignLeft ] (text "Scoutges")
            , el [ padding 8, Element.alignLeft ] (text "Dashboard")
            , el [ padding 8, Element.alignLeft ] (text "Users")
            ]
        , el [ padding 8, Element.alignRight ] (text "Account")
        ]


authBody : Model -> Element Msg
authBody model =
    column []
        [ Element.paragraph [] [ text "Please take a moment to invite your colleagues to Scoutges:" ]
        ]


signInOrAuthenticateTabView : Model -> Element Msg
signInOrAuthenticateTabView model =
    let
        ( bgCol1, bgCol2 ) =
            case model.formState of
                FillingRegistrationForm _ ->
                    ( gray6, gray7 )

                FillingSignInForm _ ->
                    ( gray7, gray6 )
    in
    row [ width fill, Region.heading 1, Font.size 32, Background.color gray6 ]
        [ el [ padding 8, width (Element.fillPortion 1), Background.color bgCol1 ]
            (Input.button [ centerX, width fill, height fill ]
                { onPress = Just (ChangeFormState (FillingSignInForm newSignInRequest))
                , label = text "Sign In"
                }
            )
        , el [ padding 8, width (Element.fillPortion 1), Background.color bgCol2 ]
            (Input.button [ centerX, width fill, height fill ]
                { onPress = Just (ChangeFormState (FillingRegistrationForm newRegistrationRequest))
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


registerFormView : RegistrationRequest -> Bool -> Element Msg
registerFormView req failed =
    column [ padding 8, spacing 8, width fill ]
        [ Input.text [ onEnter (RunRegister req) ]
            { onChange = SetGroupName
            , text = req.groupName
            , placeholder = Nothing
            , label = Input.labelAbove [ Element.alignLeft, Element.pointer ] (text "Group Name")
            }
        , Input.text [ onEnter (RunRegister req) ]
            { onChange = SetName
            , text = req.name
            , placeholder = Nothing
            , label = Input.labelAbove [ Element.alignLeft, Element.pointer ] (text "Name")
            }
        , Input.text [ onEnter (RunRegister req) ]
            { onChange = SetPhone
            , text = req.phone
            , placeholder = Nothing
            , label = Input.labelAbove [ Element.alignLeft, Element.pointer ] (text "Phone")
            }
        , Input.email [ onEnter (RunRegister req) ]
            { onChange = SetEmail
            , text = req.email
            , placeholder = Nothing
            , label = Input.labelAbove [ Element.alignLeft, Element.pointer ] (text "Email")
            }
        , Input.newPassword [ onEnter (RunRegister req) ]
            { onChange = SetPassword
            , show = False
            , text = req.password
            , placeholder = Nothing
            , label = Input.labelAbove [ Element.alignLeft, Element.pointer ] (text "Password")
            }
        , if failed then
            el [ centerX, Font.color (rgb255 255 0 0) ] (text "Invalid username or password")

          else
            el [] (text "")
        , el [ Element.paddingXY 0 16, width fill ]
            (Input.button [ centerX ]
                { label =
                    el
                        [ Background.color callToActionBackgroundColor
                        , Font.color callToActionTextColor
                        , padding 16
                        , width (fill |> Element.minimum 240 |> Element.maximum 240)
                        ]
                        (text "Register")
                , onPress = Just (RunRegister req)
                }
            )
        ]


signInFormView : SignInRequest -> Bool -> Element Msg
signInFormView req failed =
    column [ padding 8, spacing 8, width fill ]
        [ Input.email [ onEnter (RunSignIn req) ]
            { onChange = SetEmail
            , text = req.email
            , placeholder = Nothing
            , label = Input.labelAbove [ Element.alignLeft, Element.pointer ] (text "Email")
            }
        , Input.currentPassword [ onEnter (RunSignIn req) ]
            { onChange = SetPassword
            , show = False
            , text = req.password
            , placeholder = Nothing
            , label = Input.labelAbove [ Element.alignLeft, Element.pointer ] (text "Password")
            }
        , if failed then
            el [ centerX, Font.color (rgb255 255 0 0) ] (text "Invalid username or password")

          else
            el [] (text "")
        , el [ Element.paddingXY 0 16, width fill ]
            (Input.button [ centerX ]
                { label =
                    el
                        [ Background.color callToActionBackgroundColor
                        , Font.color callToActionTextColor
                        , padding 16
                        , width (fill |> Element.minimum 240 |> Element.maximum 240)
                        ]
                        (text "Sign In")
                , onPress = Just (RunSignIn req)
                }
            )
        ]


callToActionTextColor =
    white


callToActionBackgroundColor =
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


authenticationRequestEncoder : SignInRequest -> Encode.Value
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
        , ( "name", Encode.string req.name )
        , ( "group_name", Encode.string req.groupName )
        , ( "phone", Encode.string req.phone )
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


signIn : SignInRequest -> Cmd Msg
signIn req =
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
