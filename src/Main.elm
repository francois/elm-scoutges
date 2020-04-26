port module Main exposing (main)

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
import Url.Parser as Parser exposing ((</>))



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


type PartyKind
    = Customer
    | Supplier
    | Group
    | Troop


type alias Slug =
    String


type alias Party =
    { slug : Slug
    , name : String
    , kind : PartyKind
    }


type alias PartyAddress =
    { slug : Slug
    , name : String
    , address : String
    }


type alias FullParty =
    { slug : Slug
    , name : String
    , kind : PartyKind
    , addresses : List PartyAddress
    }


type alias User =
    { slug : Slug
    , name : String
    , email : String
    , phone : String
    }


type Submodel
    = SignIn String String (Request Token)
    | Register RegistrationForm (Request Token)
    | Dashboard
    | Parties (Request (List Party))
    | Users (Request (List User))
    | NotFound
    | EditParty (Request FullParty)


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    case ( flags.token, Parser.parse routeParser url ) of
        ( _, Nothing ) ->
            ( { key = key, token = Nothing, submodel = SignIn "" "" NotLoaded }, Cmd.none )

        ( _, Just SignInPage ) ->
            ( { key = key, token = Nothing, submodel = SignIn "" "" NotLoaded }, Nav.replaceUrl key (routeBuilder SignInPage) )

        ( _, Just RegistrationPage ) ->
            ( { key = key, token = Nothing, submodel = Register newRegistrationForm NotLoaded }, Nav.replaceUrl key (routeBuilder RegistrationPage) )

        ( Nothing, _ ) ->
            ( { key = key, token = Nothing, submodel = SignIn "" "" NotLoaded }, Nav.replaceUrl key (routeBuilder SignInPage) )

        ( Just token, Just DashboardPage ) ->
            ( { key = key, token = Just (Token token), submodel = Dashboard }, Nav.replaceUrl key (routeBuilder DashboardPage) )

        ( Just token, Just PartiesPage ) ->
            ( { key = key, token = Just (Token token), submodel = Parties NotLoaded }, Nav.replaceUrl key (routeBuilder PartiesPage) )

        ( Just token, Just UsersPage ) ->
            ( { key = key, token = Just (Token token), submodel = Users NotLoaded }, Nav.replaceUrl key (routeBuilder UsersPage) )

        ( Just token, Just (EditPartyPage slug) ) ->
            ( { key = key, token = Just (Token token), submodel = EditParty Loading }, Nav.replaceUrl key (routeBuilder (EditPartyPage slug)) )

        ( Just token, _ ) ->
            ( { key = key, token = Just (Token token), submodel = Dashboard }, Nav.replaceUrl key (routeBuilder DashboardPage) )


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
    | FullPartyLoaded (Result Http.Error FullParty)
    | FillInPartyName Slug String
    | FillInPartyKind Slug PartyKind
    | FillInPartyAddressName Slug Slug String
    | FillInPartyAddressAddress Slug Slug String
    | SaveFullParty FullParty
    | FullPartySaved (Result Http.Error ())
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

        ( SignInResponseReceived (Ok (Token token)), SignIn _ _ _ ) ->
            ( { model | submodel = Dashboard, token = Just (Token token) }
            , Cmd.batch [ Nav.pushUrl model.key (routeBuilder DashboardPage), manageJwtToken ( "set", token ) ]
            )

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

        ( RegistrationResponseReceived (Ok (Token token)), Register _ _ ) ->
            ( { model | submodel = Dashboard, token = Just (Token token) }
            , Cmd.batch [ Nav.pushUrl model.key (routeBuilder DashboardPage), manageJwtToken ( "set", token ) ]
            )

        ( RegistrationResponseReceived (Err err), Register form _ ) ->
            ( { model | submodel = Register form (Failure err) }, Cmd.none )

        ( PartiesLoaded (Ok parties), Parties _ ) ->
            ( { model | submodel = Parties (Loaded parties) }, Cmd.none )

        ( PartiesLoaded (Err err), Parties _ ) ->
            ( { model | submodel = Parties (Failure err) }, Cmd.none )

        ( FullPartyLoaded (Ok party), EditParty _ ) ->
            ( { model | submodel = EditParty (Loaded party) }, Cmd.none )

        ( FullPartyLoaded (Err err), EditParty _ ) ->
            ( { model | submodel = EditParty (Failure err) }, Cmd.none )

        ( FillInPartyName _ name, EditParty (Loaded fullParty) ) ->
            ( { model | submodel = EditParty (Loaded { fullParty | name = name }) }, Cmd.none )

        ( FillInPartyKind slug kind, EditParty fullParty ) ->
            ( model, Cmd.none )

        ( FillInPartyAddressName partySlug addressSlug name, EditParty fullParty ) ->
            ( model, Cmd.none )

        ( FillInPartyAddressAddress partySlug addressSlug address, EditParty fullParty ) ->
            ( model, Cmd.none )

        ( SaveFullParty fullParty, EditParty (Loaded _) ) ->
            ( { model | submodel = EditParty Loading }, saveFullParty model.token fullParty )

        ( UsersLoaded (Ok users), Users _ ) ->
            ( { model | submodel = Users (Loaded users) }, Cmd.none )

        ( UsersLoaded (Err err), Users _ ) ->
            ( { model | submodel = Users (Failure err) }, Cmd.none )

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

                Just (EditPartyPage slug) ->
                    ( { model | submodel = EditParty Loading }, getParty model.token slug )

                Just UsersPage ->
                    ( { model | submodel = Users Loading }, getAllUsers model.token )

                _ ->
                    ( model, Cmd.none )

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
            [ Element.alignLeft, padding 4 ] ++ linkStyles

        elems =
            case model.token of
                Nothing ->
                    []

                _ ->
                    [ Element.link attrs { label = text "Dashboard", url = routeBuilder DashboardPage }
                    , Element.link attrs { label = text "Parties", url = routeBuilder PartiesPage }
                    , Element.link attrs { label = text "Users", url = routeBuilder UsersPage }
                    , Element.link ([ Element.alignRight, padding 4 ] ++ linkStyles) { label = text "Account", url = routeBuilder AccountPage }
                    ]
    in
    Element.row [ Region.navigation, width fill, height (px 48), outerPadding, Background.color gray7, Font.color gray2, spacing 16 ]
        ([ Element.link attrs { label = text "SCOUTGES", url = routeBuilder RootPage } ] ++ elems)


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

                Parties list ->
                    viewParties model.key list

                Users list ->
                    viewUsers model.key list

                EditParty partyRequest ->
                    viewEditParty model.key partyRequest

                NotFound ->
                    el [] (text "404 Not Found")
    in
    el [ outerPadding, centerX, width fill, Region.mainContent ] body


viewEditParty : Nav.Key -> Request FullParty -> Element Msg
viewEditParty key partyRequest =
    let
        form =
            case partyRequest of
                Loaded party ->
                    let
                        viewAddress address =
                            Element.column [ width fill, spacing 8 ]
                                [ Input.text []
                                    { label = Input.labelAbove [ Element.alignLeft, Element.pointer, Font.bold ] (text "Name")
                                    , onChange = FillInPartyAddressName party.slug address.slug
                                    , placeholder = Nothing
                                    , text = address.name
                                    }
                                , Input.multiline []
                                    { label = Input.labelAbove [ Element.alignLeft, Element.pointer, Font.bold ] (text "Address")
                                    , onChange = FillInPartyAddressAddress party.slug address.slug
                                    , placeholder = Nothing
                                    , spellcheck = True
                                    , text = address.address
                                    }
                                ]

                        addresses =
                            List.map viewAddress party.addresses
                    in
                    [ Element.row [ width fill, spacing 8, padding 8 ]
                        [ Element.column [ width fill, spacing 24, Element.alignTop ]
                            [ h2 "Party"
                            , Input.text []
                                { label = Input.labelAbove [ Element.alignLeft, Element.pointer, Font.bold ] (text "Name")
                                , onChange = FillInPartyName party.slug
                                , placeholder = Nothing
                                , text = party.name
                                }
                            , Input.radio
                                [ padding 8
                                , spacing 4
                                ]
                                { onChange = FillInPartyKind party.slug
                                , selected = Just party.kind
                                , label = Input.labelAbove [ Element.alignLeft, Element.pointer, Font.bold ] (text "Kind")
                                , options =
                                    [ Input.option Customer (text "Customer")
                                    , Input.option Group (text "Group")
                                    , Input.option Troop (text "Troop")
                                    , Input.option Supplier (text "Supplier")
                                    ]
                                }
                            ]
                        , Element.column [ width fill, spacing 24, Element.alignTop ]
                            ([ h2 "Addresses" ] ++ addresses)
                        ]
                    , Element.row [ spacing 4 ]
                        [ Input.button ctaButtonStyles { label = text "Save", onPress = Just (SaveFullParty party) }
                        , el [] (text "or")
                        , Element.link linkStyles { label = text "return to list", url = routeBuilder PartiesPage }
                        ]
                    ]

                Failure (Http.BadBody err) ->
                    [ el [] (text ("failed to load party, bad body: " ++ err)) ]

                Failure _ ->
                    [ el [] (text "failed to load party") ]

                NotLoaded ->
                    [ el [] (text "edit party, not loaded") ]

                Loading ->
                    [ spinner ]
    in
    Element.column [ spacing 8, padding 8, width fill ] ([ h1 "Edit Party" ] ++ form)


h1 label =
    el [ Region.heading 1, Font.bold, Font.size 24, width fill, Element.alignLeft ] (text label)


h2 label =
    el [ Region.heading 2, Font.bold, Font.size 18, width fill, Element.alignLeft ] (text label)


outerPadding =
    Element.paddingXY 16 8


viewDashboard key model =
    Element.column []
        [ h1 "Welcome to Scoutges"
        ]


viewParties : Nav.Key -> Request (List Party) -> Element Msg
viewParties key partiesRequest =
    case partiesRequest of
        NotLoaded ->
            el [] (text "parties not loaded")

        Loading ->
            spinner

        Failure _ ->
            el [] (text "failed to load parties")

        Loaded list ->
            Element.table tableStyles
                { data = list
                , columns =
                    [ { header = el tableHeaderStyles (text "Name"), width = fill, view = \party -> Element.link (tableCellStyles ++ linkStyles) { url = routeBuilder (EditPartyPage party.slug), label = text party.name } }
                    , { header = el tableHeaderStyles (text "Kind"), width = fill, view = \party -> el tableCellStyles (text (kindToString party.kind)) }
                    ]
                }


ctaButtonStyles : List (Element.Attribute msg)
ctaButtonStyles =
    [ Background.color callToActionBackgroundColor, Font.color callToActionTextColor, Element.paddingXY 24 16 ]


linkStyles : List (Element.Attribute msg)
linkStyles =
    [ Font.underline, Element.pointer ]


tableStyles : List (Element.Attribute msg)
tableStyles =
    [ width fill ]


tableHeaderStyles : List (Element.Attribute msg)
tableHeaderStyles =
    [ width fill, Element.paddingXY 4 8, Background.color gray7, Font.color gray2, Font.bold, height (px 32) ]


tableCellStyles : List (Element.Attribute msg)
tableCellStyles =
    [ width fill, Element.paddingXY 8 4, Background.color white, Font.color gray1, Element.alignLeft ]


kindToString kind =
    case kind of
        Customer ->
            "Customer"

        Troop ->
            "Troop"

        Group ->
            "Group"

        Supplier ->
            "Supplier"


viewUsers : Nav.Key -> Request (List User) -> Element Msg
viewUsers key usersRequest =
    case usersRequest of
        NotLoaded ->
            el [] (text "users not loaded")

        Loading ->
            spinner

        Failure _ ->
            el [] (text "failed to load users")

        Loaded list ->
            Element.table []
                { data = list
                , columns =
                    [ { header = el tableHeaderStyles (text "Name")
                      , width = fill
                      , view = \user -> Element.link (tableCellStyles ++ linkStyles) { label = text user.name, url = routeBuilder (EditUserPage user.slug) }
                      }
                    , { header = el tableHeaderStyles (text "Email")
                      , width = fill
                      , view = \user -> Element.link (tableCellStyles ++ linkStyles) { label = text user.email, url = mailToUrl user.email }
                      }
                    , { header = el tableHeaderStyles (text "Phone")
                      , width = fill
                      , view = \user -> Element.link (tableCellStyles ++ linkStyles) { label = text user.phone, url = phoneUrl user.phone }
                      }
                    ]
                }


mailToUrl : String -> String
mailToUrl email =
    "mailto:" ++ email


phoneUrl : String -> String
phoneUrl phone =
    String.filter Char.isDigit phone


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
        [ viewTabHeaders "Register" [ ( "Sign In", routeBuilder SignInPage ), ( "Register", routeBuilder RegistrationPage ) ]
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
    [ Input.text [ onEnter (SubmitRegistration form) ]
        { onChange = FillInGroupName
        , text = form.groupName
        , placeholder = Nothing
        , label = Input.labelAbove [ Element.alignLeft, Element.pointer ] (text "Group's Name")
        }
    , Input.text [ onEnter (SubmitRegistration form) ]
        { onChange = FillInName
        , text = form.name
        , placeholder = Nothing
        , label = Input.labelAbove [ Element.alignLeft, Element.pointer ] (text "Your Name")
        }
    , Input.text [ onEnter (SubmitRegistration form) ]
        { onChange = FillInPhone
        , text = form.phone
        , placeholder = Nothing
        , label = Input.labelAbove [ Element.alignLeft, Element.pointer ] (text "Phone")
        }
    , Input.email [ onEnter (SubmitRegistration form) ]
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
    , failedMessage
    , Input.button [ centerX, onEnter (SubmitRegistration form) ]
        { onPress = Just (SubmitRegistration form)
        , label = el ctaButtonStyles (text "Register Now")
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
        [ viewTabHeaders "Sign In" [ ( "Sign In", routeBuilder SignInPage ), ( "Register", routeBuilder RegistrationPage ) ]
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
        , label = el ctaButtonStyles (text "Sign In Now")
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
                ( gray3, gray8 )
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
    | EditPartyPage Slug
    | UsersPage
    | EditUserPage Slug
    | AccountPage
    | RootPage


routeParser : Parser.Parser (Route -> a) a
routeParser =
    Parser.oneOf
        [ Parser.map SignInPage (Parser.s "sign-in")
        , Parser.map RegistrationPage (Parser.s "register")
        , Parser.map DashboardPage (Parser.s "dashboard")
        , Parser.map PartiesPage (Parser.s "parties")
        , Parser.map EditPartyPage (Parser.s "party" </> Parser.string </> Parser.s "edit")
        , Parser.map UsersPage (Parser.s "users")
        , Parser.map EditUserPage (Parser.s "user" </> Parser.string </> Parser.s "edit")
        , Parser.map AccountPage (Parser.s "account")
        , Parser.map RootPage Parser.top
        ]


routeBuilder : Route -> String
routeBuilder route =
    case route of
        RootPage ->
            Builder.absolute [] []

        SignInPage ->
            Builder.absolute [ "sign-in" ] []

        RegistrationPage ->
            Builder.absolute [ "register" ] []

        AccountPage ->
            Builder.absolute [ "account" ] []

        DashboardPage ->
            Builder.absolute [ "dashboard" ] []

        PartiesPage ->
            Builder.absolute [ "parties" ] []

        EditPartyPage slug ->
            Builder.absolute [ "party", slug, "edit" ] []

        UsersPage ->
            Builder.absolute [ "users" ] []

        EditUserPage slug ->
            Builder.absolute [ "user", slug, "edit" ] []



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
        , headers = buildHeadersForOne Nothing
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
        , headers = buildHeadersForOne Nothing
        , timeout = Nothing
        , tracker = Nothing
        }


userDecoder =
    Decode.map4 User
        (Decode.field "slug" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "email" Decode.string)
        (Decode.field "phone" Decode.string)


usersDecoder =
    Decode.list userDecoder


getAllUsers : Maybe Token -> Cmd Msg
getAllUsers maybeToken =
    Http.request
        { method = "GET"
        , url = "/api/users?select=name,email,phone,slug"
        , body = Http.emptyBody
        , expect = Http.expectJson UsersLoaded usersDecoder
        , headers = buildHeadersForMany maybeToken
        , timeout = Nothing
        , tracker = Nothing
        }


partyKindDecoder : Decode.Decoder PartyKind
partyKindDecoder =
    let
        mapper s =
            case s of
                "customer" ->
                    Decode.succeed Customer

                "supplier" ->
                    Decode.succeed Supplier

                "group" ->
                    Decode.succeed Group

                "troop" ->
                    Decode.succeed Troop

                _ ->
                    Decode.fail ("Unknown party kind: [" ++ s ++ "]")
    in
    Decode.string |> Decode.andThen mapper


partyAddressDecoder =
    Decode.map3 PartyAddress
        (Decode.field "slug" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "address" Decode.string)


partyAddressesDecoder =
    Decode.oneOf
        [ Decode.list (Decode.null ()) |> Decode.map (\_ -> [])
        , Decode.list partyAddressDecoder
        ]


completePartyDecoder =
    Decode.map4 FullParty
        (Decode.field "slug" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "kind" partyKindDecoder)
        (Decode.field "addresses" partyAddressesDecoder)


partyDecoder =
    Decode.map3 Party
        (Decode.field "slug" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "kind" partyKindDecoder)


partiesDecoder =
    Decode.list partyDecoder


getParty : Maybe Token -> Slug -> Cmd Msg
getParty maybeToken slug =
    Http.request
        { method = "GET"
        , url = Builder.absolute [ "api", "rpc", "edit_party" ] [ Builder.string "slug" slug ]
        , body = Http.emptyBody
        , expect = Http.expectJson FullPartyLoaded completePartyDecoder
        , headers = buildHeadersForOne maybeToken
        , timeout = Nothing
        , tracker = Nothing
        }


getAllParties : Maybe Token -> Cmd Msg
getAllParties maybeToken =
    Http.request
        { method = "GET"
        , url = "/api/parties?select=name,kind,slug"
        , body = Http.emptyBody
        , expect = Http.expectJson PartiesLoaded partiesDecoder
        , headers = buildHeadersForMany maybeToken
        , timeout = Nothing
        , tracker = Nothing
        }


partyKindEncoder : PartyKind -> Encode.Value
partyKindEncoder kind =
    let
        val =
            case kind of
                Customer ->
                    "customer"

                Troop ->
                    "troop"

                Group ->
                    "group"

                Supplier ->
                    "supplier"
    in
    Encode.string val


fullPartyEncoder : FullParty -> Encode.Value
fullPartyEncoder party =
    Encode.object
        [ ( "name", Encode.string party.name )
        , ( "kind", partyKindEncoder party.kind )
        , ( "slug", Encode.string party.slug )
        ]


saveFullParty : Maybe Token -> FullParty -> Cmd Msg
saveFullParty maybeToken fullParty =
    Http.request
        { method = "POST"
        , url = "/api/rpc/save_full_party"
        , body = Http.jsonBody (fullPartyEncoder fullParty)
        , expect = Http.expectWhatever FullPartySaved
        , headers = buildHeadersForOne maybeToken ++ [ Http.header "Prefer" "params=single-object" ]
        , timeout = Nothing
        , tracker = Nothing
        }


buildHeadersForMany : Maybe Token -> List Http.Header
buildHeadersForMany maybeToken =
    let
        authHeaders =
            case maybeToken of
                Nothing ->
                    []

                Just (Token token) ->
                    [ Http.header "Authorization" ("Bearer " ++ token) ]
    in
    [ Http.header "Accept" "application/json" ] ++ authHeaders


buildHeadersForOne : Maybe Token -> List Http.Header
buildHeadersForOne maybeToken =
    let
        authHeaders =
            case maybeToken of
                Nothing ->
                    []

                Just (Token token) ->
                    [ Http.header "Authorization" ("Bearer " ++ token) ]
    in
    [ Http.header "Accept" "application/vnd.pgrst.object+json" ] ++ authHeaders



---- PORTS ----


port manageJwtToken : ( String, String ) -> Cmd msg



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
