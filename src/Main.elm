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


type alias RegistrationForm =
    { email : String, password : String, name : String, groupName : String, phone : String }


type alias Party =
    { name : String }


type alias User =
    { name : String }


type Submodel
    = SignIn String String (Request Token)
    | Register RegistrationForm (Request Token)
    | Dashboard
    | Parties (Request (List Party))
    | Users (Request (List User))
    | NotFound


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    case ( flags.token, Parser.parse routeParser url ) of
        ( _, Nothing ) ->
            ( { key = key, token = Nothing, submodel = SignIn "" "" NotLoaded }, Cmd.none )

        ( _, Just SignInPage ) ->
            ( { key = key, token = Nothing, submodel = SignIn "" "" NotLoaded }, Nav.replaceUrl key "/sign-in" )

        ( _, Just RegistrationPage ) ->
            ( { key = key, token = Nothing, submodel = Register newRegistrationForm NotLoaded }, Nav.replaceUrl key "/register" )

        ( Nothing, _ ) ->
            ( { key = key, token = Nothing, submodel = SignIn "" "" NotLoaded }, Nav.replaceUrl key "/sign-in" )

        ( Just token, Just DashboardPage ) ->
            ( { key = key, token = Just (Token token), submodel = Dashboard }, Nav.replaceUrl key "/dashboard" )

        ( Just token, Just PartiesPage ) ->
            ( { key = key, token = Just (Token token), submodel = Parties NotLoaded }, Nav.replaceUrl key "/parties" )

        ( Just token, Just UsersPage ) ->
            ( { key = key, token = Just (Token token), submodel = Users NotLoaded }, Nav.replaceUrl key "/users" )


newRegistrationForm =
    { email = "", password = "", name = "", groupName = "", phone = "" }



---- UPDATE ----


type Msg
    = FillInEmail String
    | FillInPassword String
    | FillInName String
    | FillInGroupName String
    | FillInPhone String
    | SubmitSignIn String String
    | SignInResponseReceived (Result Http.Error Token)
    | SubmitRegistration RegistrationForm
    | RegistrationResponseReceived (Result Http.Error Token)
    | PartiesLoaded (Result Http.Error (List Party))
    | UsersLoaded (Result Http.Error (List User))
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

        ( FillInEmail str, Register form tokenRequest ) ->
            ( { model | submodel = Register { form | email = str } tokenRequest }, Cmd.none )

        ( FillInPassword str, Register form tokenRequest ) ->
            ( { model | submodel = Register { form | password = str } tokenRequest }, Cmd.none )

        ( FillInName str, Register form tokenRequest ) ->
            ( { model | submodel = Register { form | name = str } tokenRequest }, Cmd.none )

        ( FillInGroupName str, Register form tokenRequest ) ->
            ( { model | submodel = Register { form | groupName = str } tokenRequest }, Cmd.none )

        ( FillInPhone str, Register form tokenRequest ) ->
            ( { model | submodel = Register { form | phone = str } tokenRequest }, Cmd.none )

        ( SubmitRegistration form, Register _ _ ) ->
            ( { model | submodel = Register form Loading }, submitRegistration form )

        ( RegistrationResponseReceived (Ok token), Register _ _ ) ->
            ( { model | submodel = Dashboard, token = Just token }, Nav.pushUrl model.key "/dashboard" )

        ( RegistrationResponseReceived (Err err), Register form _ ) ->
            ( { model | submodel = Register form (Failure err) }, Cmd.none )

        ( LinkClicked target, _ ) ->
            case target of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        ( UrlChanged url, _ ) ->
            case Parser.parse routeParser url of
                Nothing ->
                    ( { model | submodel = NotFound }, Cmd.none )

                Just SignInPage ->
                    ( { model | token = Nothing, submodel = SignIn "" "" NotLoaded }, Cmd.none )

                Just RegistrationPage ->
                    ( { model | token = Nothing, submodel = Register newRegistrationForm NotLoaded }, Cmd.none )

                Just DashboardPage ->
                    ( { model | submodel = Dashboard }, Cmd.none )

                Just PartiesPage ->
                    ( { model | submodel = Parties Loading }, getAllParties model.token )

                Just UsersPage ->
                    ( { model | submodel = Users Loading }, getAllUsers model.token )

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
        attrs =
            [ Element.alignLeft, padding 4 ]

        elems =
            case model.token of
                Nothing ->
                    []

                _ ->
                    [ Element.link attrs { label = text "Dashboard", url = "/dashboard" }
                    , Element.link attrs { label = text "Parties", url = "/parties" }
                    , Element.link attrs { label = text "Users", url = "/users" }
                    , Element.link [ Element.alignRight, padding 4 ] { label = text "Account", url = "/account" }
                    ]
    in
    Element.row [ Region.navigation, width fill, height (px 48), outerPadding, Background.color gray7, Font.color gray2, spacing 16 ]
        ([ Element.link attrs { label = text "SCOUTGES", url = "/" } ] ++ elems)


viewSubmodel : Model -> Element Msg
viewSubmodel model =
    let
        body =
            case model.submodel of
                SignIn email password tokenRequest ->
                    viewSignIn model.key email password tokenRequest

                Register form tokenRequest ->
                    viewRegistration model.key form tokenRequest

                Dashboard ->
                    viewDashboard model.key model.submodel

                Users _ ->
                    el [] (text "Users not handled yet")

                Parties _ ->
                    el [] (text "Parties not handled yet")

                NotFound ->
                    el [] (text "404 Not Found")
    in
    el [ outerPadding, centerX, Region.mainContent ] body


outerPadding =
    Element.paddingXY 16 8


viewDashboard key model =
    Element.column []
        [ el [ Region.heading 1, Font.bold, Font.size 24 ] (text "Welcome to Scoutges")
        ]


viewRegistration : Nav.Key -> RegistrationForm -> Request Token -> Element Msg
viewRegistration key form requestToken =
    let
        contents =
            case requestToken of
                Loading ->
                    [ el [ width fill, height fill ] Colors.spinner ]

                Failure (Http.BadUrl str) ->
                    registrationForm form (Just ("Bad url: " ++ str))

                Failure Http.NetworkError ->
                    registrationForm form (Just "Network error")

                Failure Http.Timeout ->
                    registrationForm form (Just "Timed out")

                Failure (Http.BadStatus code) ->
                    registrationForm form (Just ("Status " ++ String.fromInt code))

                Failure (Http.BadBody str) ->
                    registrationForm form (Just ("Bad body: " ++ str))

                NotLoaded ->
                    registrationForm form Nothing

                Loaded _ ->
                    registrationForm form Nothing
    in
    Element.column [ centerX, centerY, spacing 8, width (px 400), height (px 624), Background.color gray7 ]
        [ viewTabHeaders "Register" [ ( "Sign In", "/sign-in" ), ( "Register", "/register" ) ]
        , Element.column [ width fill, spacing 16, padding 8 ] contents
        ]


registrationForm : RegistrationForm -> Maybe String -> List (Element Msg)
registrationForm form reason =
    let
        attrs =
            [ Background.color errorBackgroundColor, Font.color errorTextColor, centerX, padding 8, width fill ]

        failedMessage =
            case reason of
                Nothing ->
                    el attrs (text "")

                Just str ->
                    el attrs (text ("Invalid email or password. " ++ str))
    in
    [ Input.email [ onEnter (SubmitRegistration form) ]
        { onChange = FillInEmail
        , text = form.email
        , placeholder = Nothing
        , label = Input.labelAbove [ Element.alignLeft, Element.pointer ] (text "Email")
        }
    , Input.newPassword [ onEnter (SubmitRegistration form) ]
        { onChange = FillInPassword
        , text = form.password
        , placeholder = Nothing
        , show = False
        , label = Input.labelAbove [ Element.alignLeft, Element.pointer ] (text "Password")
        }
    , Input.text [ onEnter (SubmitRegistration form) ]
        { onChange = FillInName
        , text = form.name
        , placeholder = Nothing
        , label = Input.labelAbove [ Element.alignLeft, Element.pointer ] (text "Your Name")
        }
    , Input.text [ onEnter (SubmitRegistration form) ]
        { onChange = FillInGroupName
        , text = form.groupName
        , placeholder = Nothing
        , label = Input.labelAbove [ Element.alignLeft, Element.pointer ] (text "Group's Name")
        }
    , Input.text [ onEnter (SubmitRegistration form) ]
        { onChange = FillInPhone
        , text = form.phone
        , placeholder = Nothing
        , label = Input.labelAbove [ Element.alignLeft, Element.pointer ] (text "Phone")
        }
    , failedMessage
    , Input.button [ centerX, onEnter (SubmitRegistration form) ]
        { onPress = Just (SubmitRegistration form)
        , label = el [ Background.color callToActionBackgroundColor, Font.color callToActionTextColor, padding 16 ] (text "Register Now")
        }
    ]


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
    Element.column [ centerX, centerY, spacing 8, width (px 400), height (px 368), Background.color gray7 ]
        [ viewTabHeaders "Sign In" [ ( "Sign In", "/sign-in" ), ( "Register", "/register" ) ]
        , Element.column [ width fill, spacing 16, padding 8 ] contents
        ]


signInForm : String -> String -> Maybe String -> List (Element Msg)
signInForm email password reason =
    let
        attrs =
            [ Background.color errorBackgroundColor, Font.color errorTextColor, centerX, padding 8, width fill ]

        failedMessage =
            case reason of
                Nothing ->
                    el attrs (text "")

                Just str ->
                    el attrs (text ("Invalid email or password. " ++ str))
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
    Element.link [ width fill, padding 16, Background.color bg, Font.color fg ] { label = text label, url = url }



---- SUBSCRIPTIONS ----


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



---- ROUTING ----


type Route
    = SignInPage
    | RegistrationPage
    | DashboardPage
    | PartiesPage
    | UsersPage


routeParser : Parser.Parser (Route -> a) a
routeParser =
    Parser.oneOf
        [ Parser.map SignInPage (Parser.s "sign-in")
        , Parser.map RegistrationPage (Parser.s "register")
        , Parser.map DashboardPage (Parser.s "dashboard")
        , Parser.map PartiesPage (Parser.s "parties")
        , Parser.map UsersPage (Parser.s "users")
        ]



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


tokenDecoder : Decode.Decoder Token
tokenDecoder =
    Decode.map Token (Decode.field "token" Decode.string)


submitSignIn : String -> String -> Cmd Msg
submitSignIn email password =
    Http.request
        { method = "POST"
        , url = "/api/rpc/sign_in"
        , body = Http.jsonBody (signInEncoder email password)
        , expect = Http.expectJson SignInResponseReceived tokenDecoder
        , headers = buildHeaders Nothing
        , timeout = Nothing
        , tracker = Nothing
        }


registrationEncoder : RegistrationForm -> Encode.Value
registrationEncoder form =
    Encode.object
        [ ( "email", Encode.string form.email )
        , ( "password", Encode.string form.password )
        , ( "name", Encode.string form.name )
        , ( "group_name", Encode.string form.groupName )
        , ( "phone", Encode.string form.phone )
        ]


submitRegistration : RegistrationForm -> Cmd Msg
submitRegistration form =
    Http.request
        { method = "POST"
        , url = "/api/rpc/register"
        , body = Http.jsonBody (registrationEncoder form)
        , expect = Http.expectJson RegistrationResponseReceived tokenDecoder
        , headers = buildHeaders Nothing
        , timeout = Nothing
        , tracker = Nothing
        }


userDecoder =
    Decode.map User (Decode.field "name" Decode.string)


usersDecoder =
    Decode.list userDecoder


getAllUsers : Maybe Token -> Cmd Msg
getAllUsers maybeToken =
    Http.request
        { method = "GET"
        , url = "/api/users?select=name"
        , body = Http.emptyBody
        , expect = Http.expectJson UsersLoaded usersDecoder
        , headers = buildHeaders maybeToken
        , timeout = Nothing
        , tracker = Nothing
        }


partyDecoder =
    Decode.map Party (Decode.field "name" Decode.string)


partiesDecoder =
    Decode.list partyDecoder


getAllParties : Maybe Token -> Cmd Msg
getAllParties maybeToken =
    Http.request
        { method = "GET"
        , url = "/api/parties?select=name"
        , body = Http.emptyBody
        , expect = Http.expectJson PartiesLoaded partiesDecoder
        , headers = buildHeaders maybeToken
        , timeout = Nothing
        , tracker = Nothing
        }


buildHeaders : Maybe Token -> List Http.Header
buildHeaders maybeToken =
    let
        authHeaders =
            case maybeToken of
                Nothing ->
                    []

                Just (Token token) ->
                    [ Http.header "Authorization" ("Bearer " ++ token) ]
    in
    [ Http.header "Accept" "application/json" ] ++ authHeaders



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
