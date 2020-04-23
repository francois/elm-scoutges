port module Main exposing (main)

import Authenticate
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
import Url
import Url.Builder as Builder
import Url.Parser as Parser



---- MODEL ----


type Request a
    = NotLoaded
    | Loading
    | Loaded a
    | Failure Http.Error


type alias Flags =
    { token : Maybe JwtToken
    , now : Int
    }


type Data
    = SignInData SignInForm
    | RegistrationData RegistrationForm


type alias Model =
    { authenticationState : AuthenticationState
    , users : Request (List User)
    , key : Nav.Key
    , route : ( Route, Maybe Data )
    , parties : Request (List Party)
    , auth : Authenticate.Model
    }


type alias User =
    { name : String
    , email : String
    , phone : String
    , registeredAt : String
    }


type alias JwtToken =
    String


type AuthenticationState
    = Anonymous
    | InProgress
    | Failed
    | Authenticated JwtToken


type alias RegistrationResponse =
    { token : String
    }


type alias RegistrationForm =
    { email : String
    , password : String
    , name : String
    , groupName : String
    , phone : String
    }


type alias SignInResponse =
    { token : String
    }


type alias SignInForm =
    { email : String
    , password : String
    }


init : Flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    case Parser.parse routeParser url of
        Just SignIn ->
            initWithSignIn key

        Just Register ->
            ( { authenticationState = Anonymous
              , users = NotLoaded
              , key = key
              , route = ( Register, Just (RegistrationData newRegistrationRequest) )
              , parties = NotLoaded
              , auth = Authenticate.init
              }
            , manageJwtToken ( "clear", "" )
            )

        Just _ ->
            case flags.token of
                Just token ->
                    case parseJWT token of
                        Ok details ->
                            if flags.now < details.exp then
                                ( { authenticationState = Authenticated token
                                  , users = NotLoaded
                                  , key = key
                                  , route = ( Dashboard, Nothing )
                                  , parties = NotLoaded
                                  , auth = Authenticate.init
                                  }
                                , Nav.replaceUrl key (buildUrl Dashboard)
                                )

                            else
                                initWithSignIn key

                        Err _ ->
                            initWithSignIn key

                Nothing ->
                    initWithSignIn key

        Nothing ->
            initWithSignIn key


initWithSignIn : Nav.Key -> ( Model, Cmd Msg )
initWithSignIn key =
    ( { authenticationState = Anonymous
      , users = NotLoaded
      , key = key
      , route = ( SignIn, Just (SignInData newSignInRequest) )
      , parties = NotLoaded
      , auth = Authenticate.init
      }
    , Cmd.batch
        [ manageJwtToken ( "clear", "" )
        , Nav.replaceUrl key (buildUrl SignIn)
        ]
    )


type JwtError
    = FailedJWTDecode String


type alias JwtDetails =
    { exp : Int
    , sub : String
    , jti : String
    }


newSignInRequest : SignInForm
newSignInRequest =
    { email = "", password = "" }


newRegistrationRequest : RegistrationForm
newRegistrationRequest =
    { email = "", password = "", groupName = "", name = "", phone = "" }



---- UPDATE ----


type Msg
    = SignInResult (Result Http.Error SignInResponse)
    | RegisterResult (Result Http.Error RegistrationResponse)
    | UsersLoaded (Result Http.Error (List User))
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | Go Route
    | PartiesLoaded (Result Http.Error (List Party))
    | Auth Authenticate.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PartiesLoaded (Ok parties) ->
            ( { model | parties = Loaded parties }, Cmd.none )

        PartiesLoaded (Err err) ->
            ( { model | parties = Failure err }, Cmd.none )

        SignInResult (Ok resp) ->
            ( { model | authenticationState = Authenticated resp.token, users = Loading }
            , Cmd.batch [ getAllUsers resp.token, manageJwtToken ( "set", resp.token ), Nav.pushUrl model.key (buildUrl Dashboard) ]
            )

        SignInResult (Err _) ->
            ( { model | authenticationState = Failed, users = NotLoaded }, Cmd.none )

        RegisterResult (Ok resp) ->
            ( { model | authenticationState = Authenticated resp.token, users = Loading }
            , Cmd.batch [ getAllUsers resp.token, manageJwtToken ( "set", resp.token ), Nav.pushUrl model.key (buildUrl Dashboard) ]
            )

        RegisterResult (Err _) ->
            ( { model | authenticationState = Failed, users = NotLoaded }, Cmd.none )

        UsersLoaded (Ok users) ->
            ( { model | users = Loaded users }, Cmd.none )

        UsersLoaded (Err err) ->
            ( { model | users = Failure err }, Cmd.none )

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            case Parser.parse routeParser url of
                Just SignIn ->
                    ( { model | route = ( SignIn, Just (SignInData newSignInRequest) ) }, Cmd.none )

                Just Register ->
                    ( { model | route = ( Register, Just (RegistrationData newRegistrationRequest) ) }, Cmd.none )

                Just Dashboard ->
                    case model.authenticationState of
                        Authenticated token ->
                            ( { model | route = ( Dashboard, Nothing ), users = Loading }, getAllUsers token )

                        _ ->
                            ( model, Cmd.none )

                Just Parties ->
                    case model.authenticationState of
                        Authenticated token ->
                            ( { model | route = ( Parties, Nothing ), parties = Loading }, getAllParties token )

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( { model | route = ( SignIn, Just (SignInData newSignInRequest) ) }, Cmd.none )

        Go route ->
            ( model, Nav.pushUrl model.key (buildUrl route) )

        Auth m ->
            let
                ( newmodel, cmds ) =
                    Authenticate.update m model.auth
            in
            ( { model | auth = newmodel }, cmds )



---- VIEW ----


view : Model -> Browser.Document Msg
view model =
    let
        body =
            case model.route of
                ( SignIn, Just (SignInData req) ) ->
                    Authenticate.view model.auth
                        |> Element.map Auth

                ( Register, Just (RegistrationData req) ) ->
                    Authenticate.view model.auth
                        |> Element.map Auth

                ( Dashboard, _ ) ->
                    viewDashboard model

                ( Parties, _ ) ->
                    viewParties model

                _ ->
                    el [] (text "fallthrough")
    in
    { title = "URL Interceptor"
    , body = [ Element.layout [ Font.color gray1, Background.color white, centerX ] body ]
    }


viewDashboard : Model -> Element Msg
viewDashboard model =
    column [ spacing 16, width fill ]
        [ el [ padding 8, width fill, Background.color gray7, Font.color gray2 ] (navbarView model)
        , column [ padding 8, width fill, Font.alignLeft ]
            [ el [ Font.size 32, Font.bold, Region.heading 1 ] (text "Welcome to Scoutges")
            , el [ Element.paddingXY 0 8 ] (authBody model)
            ]
        ]


viewParties : Model -> Element Msg
viewParties model =
    let
        body =
            case model.parties of
                Loaded list ->
                    let
                        parties =
                            List.sortBy (\party -> String.toLower party.name) list
                    in
                    Element.table [ Border.color gray6, Border.width 1, Border.solid ]
                        { data = parties
                        , columns =
                            [ { header = el [ height (px 40), Border.color gray7, Border.width 1, Border.solid, Background.color gray1, Font.color white, Font.bold, Font.size 24 ] (text "Name")
                              , width = fill
                              , view = \party -> text party.name
                              }
                            , { header = el [ height (px 40), Border.color gray7, Border.width 1, Border.solid, Background.color gray1, Font.color white, Font.bold, Font.size 24 ] (text "Kind")
                              , width = fill
                              , view =
                                    \party ->
                                        case party.kind of
                                            Customer ->
                                                text "Customer"

                                            Supplier ->
                                                text "Supplier"

                                            Troop ->
                                                text "Troop"

                                            Group ->
                                                text "Group"
                              }
                            ]
                        }

                Loading ->
                    spinner

                NotLoaded ->
                    el [] (text "not loaded")

                Failure _ ->
                    el [] (text "Failed to load parties ; check logs")
    in
    column [ spacing 16, width fill ]
        [ el [ padding 8, width fill, Background.color gray7, Font.color gray2 ] (navbarView model)
        , column [ padding 8, width fill, Font.alignLeft ]
            [ el [ Font.size 32, Font.bold, Region.heading 1 ] (text "Parties")
            , body
            ]
        ]


navbarView : Model -> Element Msg
navbarView _ =
    row [ Element.alignTop, width fill, Region.navigation ]
        [ row [ width fill, spacing 8 ]
            [ el [ padding 8, Element.alignLeft ] (link [] { label = el [] (text "Scoutges"), url = buildUrl Home })
            , el [ padding 8, Element.alignLeft ] (link [] { label = el [] (text "Parties"), url = buildUrl Parties })
            , el [ padding 8, Element.alignLeft ] (text "Users")
            ]
        , el [ padding 8, Element.alignRight ] (text "Account")
        ]


authBody : Model -> Element Msg
authBody model =
    let
        table =
            case model.users of
                NotLoaded ->
                    Element.none

                Loading ->
                    spinner

                Loaded users ->
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

                Failure _ ->
                    el [] (text "Failed to load parties ; check logs")
    in
    column []
        [ Element.paragraph [] [ text "Please take a moment to invite your colleagues to Scoutges:" ]
        , table
        ]



---- JSON Encoders & Decoders ----


type PartyKind
    = Customer
    | Troop
    | Group
    | Supplier


type alias PartySlug =
    String


type alias Party =
    { slug : PartySlug
    , name : String
    , kind : PartyKind
    }


partiesListDecoder : Decode.Decoder (List Party)
partiesListDecoder =
    Decode.list partyDecoder


partyDecoder : Decode.Decoder Party
partyDecoder =
    Decode.map3 Party
        (Decode.field "slug" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "kind" partyKindDecoder)


partyKindDecoder : Decode.Decoder PartyKind
partyKindDecoder =
    Decode.map
        (\str ->
            case str of
                "troop" ->
                    Troop

                "group" ->
                    Group

                "supplier" ->
                    Supplier

                _ ->
                    Customer
        )
        Decode.string


authenticationRequestEncoder : SignInForm -> Encode.Value
authenticationRequestEncoder req =
    Encode.object
        [ ( "email", Encode.string req.email )
        , ( "password", Encode.string req.password )
        ]


jwtDecoder : Decode.Decoder JwtDetails
jwtDecoder =
    Decode.map3 JwtDetails
        (Decode.field "exp" Decode.int)
        (Decode.field "sub" Decode.string)
        (Decode.field "jti" Decode.string)


authenticationResponseDecoder : Decode.Decoder SignInResponse
authenticationResponseDecoder =
    Decode.map SignInResponse (Decode.field "token" Decode.string)


registrationRequestEncoder : RegistrationForm -> Encode.Value
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
    Decode.map4 User
        (Decode.field "name" Decode.string)
        (Decode.field "email" Decode.string)
        (Decode.field "phone" Decode.string)
        (Decode.field "registered_at" Decode.string)


userListDecoder : Decode.Decoder (List User)
userListDecoder =
    Decode.list userDecoder



---- Parsers ----


parseJWT : JwtToken -> Result JwtError JwtDetails
parseJWT token =
    let
        parts =
            String.split "." token

        jsondata =
            case parts of
                hdr :: data :: sig ->
                    Base64.decode data

                [ _ ] ->
                    Err "JWT syntax error"

                [] ->
                    Err "JWT syntax error"

        parseddata : Result JwtError JwtDetails
        parseddata =
            case jsondata of
                Ok str ->
                    let
                        parsed : Result Decode.Error JwtDetails
                        parsed =
                            Decode.decodeString jwtDecoder str
                    in
                    case parsed of
                        Ok jwt ->
                            Ok jwt

                        Err (Decode.Field name cause) ->
                            Err (FailedJWTDecode ("Failed to decode [" ++ name ++ "]"))

                        Err (Decode.Index idx cause) ->
                            Err (FailedJWTDecode ("Failed to decode at index " ++ String.fromInt idx))

                        Err (Decode.OneOf causes) ->
                            Err (FailedJWTDecode ("Failed to decode one of " ++ String.fromInt (List.length causes) ++ "variants"))

                        Err (Decode.Failure error value) ->
                            Err (FailedJWTDecode ("Failed to decode: " ++ error))

                Err reason ->
                    Err (FailedJWTDecode reason)
    in
    parseddata



---- Commands ----


register : RegistrationForm -> Cmd Msg
register req =
    Http.post
        { url = "/api/rpc/register"
        , body = Http.jsonBody (registrationRequestEncoder req)
        , expect = Http.expectJson RegisterResult registrationResponseDecoder
        }


signIn : SignInForm -> Cmd Msg
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
        , url = "/api/users?select=name,email,phone,registered_at"
        , body = Http.emptyBody
        , expect = Http.expectJson UsersLoaded userListDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


getAllParties : JwtToken -> Cmd Msg
getAllParties token =
    Http.request
        { method = "GET"
        , headers = [ Http.header "Authorization" ("Bearer " ++ token), Http.header "Accept" "application/json" ]
        , url = "/api/parties?select=slug,name,kind"
        , body = Http.emptyBody
        , expect = Http.expectJson PartiesLoaded partiesListDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



---- ROUTING ----


type Route
    = SignIn
    | Register
    | Dashboard
    | Home
    | Parties


buildUrl : Route -> String
buildUrl route =
    case route of
        SignIn ->
            Builder.absolute [ "sign-in" ] []

        Register ->
            Builder.absolute [ "register" ] []

        Dashboard ->
            Builder.absolute [ "dashboard" ] []

        Parties ->
            Builder.absolute [ "parties" ] []

        Home ->
            Builder.absolute [ "" ] []


routeParser : Parser.Parser (Route -> a) a
routeParser =
    Parser.oneOf
        [ Parser.map SignIn (Parser.s "sign-in")
        , Parser.map Register (Parser.s "register")
        , Parser.map Dashboard (Parser.s "dashboard")
        , Parser.map Parties (Parser.s "parties")
        , Parser.map Home Parser.top
        ]



---- PORTS ----


port manageJwtToken : ( String, String ) -> Cmd msg



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
