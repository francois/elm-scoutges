port module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Cmd.Extra
import Debug
import Element exposing (Color, Element, alignLeft, alignRight, alignTop, centerX, centerY, column, el, fill, height, padding, px, rgb255, row, spacing, text, width)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import Html
import Html.Events
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Url



---- MODEL ----


type alias Flags =
    { token : Maybe JwtToken }


type alias Model =
    { formState : FormState
    , authenticationState : AuthenticationState
    , users : Maybe (List User)
    , key : Nav.Key
    , url : Url.Url
    }


type alias User =
    { name : String
    , email : String
    , groupName : String
    , phone : String
    , registeredAt : String
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


init : Flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    case flags.token of
        Just token ->
            ( { formState = FillingSignInForm newSignInRequest
              , authenticationState = Authenticated token
              , users = Nothing
              , key = key
              , url = url
              }
            , Cmd.none
            )

        Nothing ->
            ( { formState = FillingSignInForm newSignInRequest
              , authenticationState = Unknown
              , users = Nothing
              , key = key
              , url = url
              }
            , Cmd.none
            )


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
    | UsersLoaded (Result Http.Error (List User))
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url


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

                _ ->
                    ( model, Cmd.none )

        SetPhone str ->
            case model.formState of
                FillingRegistrationForm req ->
                    let
                        newReq =
                            { req | phone = str }
                    in
                    ( { model | formState = FillingRegistrationForm newReq }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        SetGroupName str ->
            case model.formState of
                FillingRegistrationForm req ->
                    let
                        newReq =
                            { req | groupName = str }
                    in
                    ( { model | formState = FillingRegistrationForm newReq }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        RunSignIn req ->
            ( { model | authenticationState = InProgress }, signIn req )

        RunRegister req ->
            ( { model | authenticationState = InProgress }, register req )

        SignInResult (Ok resp) ->
            { model | authenticationState = Authenticated resp.token }
                |> Cmd.Extra.withCmds [ getAllUsers resp.token, storeJwtToken resp.token ]

        SignInResult (Err _) ->
            ( { model | authenticationState = Failed }, Cmd.none )

        RegisterResult (Ok resp) ->
            { model | authenticationState = Authenticated resp.token }
                |> Cmd.Extra.withCmds [ getAllUsers resp.token, storeJwtToken resp.token ]

        RegisterResult (Err _) ->
            ( { model | authenticationState = Failed }, Cmd.none )

        ChangeFormState newState ->
            ( { model | formState = newState, authenticationState = Unknown }, Cmd.none )

        UsersLoaded (Ok users) ->
            ( { model | users = Just users }, Cmd.none )

        UsersLoaded (Err _) ->
            ( model, Cmd.none )

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            ( { model | url = url }
            , Cmd.none
            )



---- VIEW ----


view : Model -> Browser.Document Msg
view model =
    let
        failed =
            case model.authenticationState of
                Failed ->
                    True

                _ ->
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

                _ ->
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
    { title = "URL Interceptor"
    , body = [ Element.layout [ Font.color gray1, Background.color white, centerX ] body ]
    }


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
navbarView _ =
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
    let
        table =
            case model.users of
                Nothing ->
                    Element.none

                Just users ->
                    Element.table []
                        { data = users
                        , columns =
                            [ { header = el [ Font.bold ] (Element.text "Name")
                              , width = fill
                              , view =
                                    \user ->
                                        Element.text user.name
                              }
                            , { header = el [ Font.bold ] (Element.text "Email")
                              , width = fill
                              , view =
                                    \user ->
                                        Element.text user.email
                              }
                            ]
                        }
    in
    column []
        [ Element.paragraph [] [ text "Please take a moment to invite your colleagues to Scoutges:" ]
        , table
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
                        (text "Register Now")
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
                        (text "Sign In Now")
                , onPress = Just (RunSignIn req)
                }
            )
        ]


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


userDecoder : Decode.Decoder User
userDecoder =
    Decode.map5 User
        (Decode.field "user_name" Decode.string)
        (Decode.field "user_email" Decode.string)
        (Decode.field "group_name" Decode.string)
        (Decode.field "user_phone" Decode.string)
        (Decode.field "user_registered_at" Decode.string)


userListDecoder : Decode.Decoder (List User)
userListDecoder =
    Decode.list userDecoder



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


getAllUsers : JwtToken -> Cmd Msg
getAllUsers token =
    Http.request
        { method = "GET"
        , headers = [ Http.header "Authorization" ("Bearer " ++ token), Http.header "Accept" "application/json" ]
        , url = "/api/users"
        , body = Http.emptyBody
        , expect = Http.expectJson UsersLoaded userListDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



---- PORTS ----


port storeJwtToken : String -> Cmd msg



---- PROGRAM ----


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
