module Authenticate exposing (Model, Msg, init, update, view)

import Colors exposing (..)
import Element exposing (Color, Element, centerX, centerY, column, el, fill, height, link, padding, px, rgb255, row, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import Html.Events
import Json.Decode as Decode
import Json.Encode as Encode


type alias JwtToken =
    String


type AuthenticationState
    = Anonymous
    | InProgress
    | Failed
    | Authenticated JwtToken


type Page
    = SignInPage
    | RegisterPage


type alias Model =
    { email : String
    , password : String
    , name : String
    , groupName : String
    , phone : String
    , page : Page
    , authenticationState : AuthenticationState
    }


type Msg
    = FillInEmail String
    | FillInPassword String
    | FillInName String
    | FillInGroupName String
    | FillInPhone String
    | RunSignIn
    | RunRegister
    | Go Page


init : Model
init =
    { email = "", password = "", name = "", groupName = "", phone = "", page = SignInPage, authenticationState = Anonymous }


update : Msg -> Model -> ( Model, Cmd a )
update msg model =
    case msg of
        FillInEmail str ->
            ( { model | email = str }, Cmd.none )

        FillInPassword str ->
            ( { model | password = str }, Cmd.none )

        FillInName str ->
            ( { model | name = str }, Cmd.none )

        FillInGroupName str ->
            ( { model | groupName = str }, Cmd.none )

        FillInPhone str ->
            ( { model | phone = str }, Cmd.none )

        RunSignIn ->
            ( model, Cmd.none )

        RunRegister ->
            ( model, Cmd.none )

        Go page ->
            ( { init | page = page }, Cmd.none )


view : Model -> Element Msg
view model =
    case model.page of
        SignInPage ->
            viewSignIn model

        RegisterPage ->
            viewRegister model


viewSignIn : Model -> Element Msg
viewSignIn model =
    let
        body =
            case model.authenticationState of
                InProgress ->
                    el [ height fill, width (fill |> Element.minimum 400 |> Element.maximum 480) ] spinner

                Failed ->
                    signInFormView model True

                Anonymous ->
                    signInFormView model False

                Authenticated _ ->
                    el [] (text "should not happen, so I have a modelling error")
    in
    column [ centerY, centerX, Background.color gray7, width (px 400), height (px 352) ]
        [ signInOrAuthenticateTabView model
        , body
        ]


viewRegister : Model -> Element Msg
viewRegister model =
    let
        body =
            case model.authenticationState of
                InProgress ->
                    el [ height fill, width (fill |> Element.minimum 400 |> Element.maximum 480) ] spinner

                Failed ->
                    registerFormView model True

                Anonymous ->
                    registerFormView model False

                Authenticated _ ->
                    el [] (text "should not happen, so I have a modelling error")
    in
    column [ centerY, centerX, Background.color gray7, width (px 400), height (px 576) ]
        [ signInOrAuthenticateTabView model
        , body
        ]


registerFormView : Model -> Bool -> Element Msg
registerFormView req failed =
    column [ padding 8, spacing 8, width fill ]
        [ Input.text [ onEnter RunRegister ]
            { onChange = FillInGroupName
            , text = req.groupName
            , placeholder = Nothing
            , label = Input.labelAbove [ Element.alignLeft, Element.pointer ] (text "Group Name")
            }
        , Input.text [ onEnter RunRegister ]
            { onChange = FillInName
            , text = req.name
            , placeholder = Nothing
            , label = Input.labelAbove [ Element.alignLeft, Element.pointer ] (text "Name")
            }
        , Input.text [ onEnter RunRegister ]
            { onChange = FillInPhone
            , text = req.phone
            , placeholder = Nothing
            , label = Input.labelAbove [ Element.alignLeft, Element.pointer ] (text "Phone")
            }
        , Input.email [ onEnter RunRegister ]
            { onChange = FillInEmail
            , text = req.email
            , placeholder = Nothing
            , label = Input.labelAbove [ Element.alignLeft, Element.pointer ] (text "Email")
            }
        , Input.newPassword [ onEnter RunRegister ]
            { onChange = FillInPassword
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
                , onPress = Just RunRegister
                }
            )
        ]


signInFormView : Model -> Bool -> Element Msg
signInFormView req failed =
    column [ padding 8, spacing 8, width fill ]
        [ Input.email [ onEnter RunSignIn ]
            { onChange = FillInEmail
            , text = req.email
            , placeholder = Nothing
            , label = Input.labelAbove [ Element.alignLeft, Element.pointer ] (text "Email")
            }
        , Input.currentPassword [ onEnter RunSignIn ]
            { onChange = FillInPassword
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
                , onPress = Just RunSignIn
                }
            )
        ]


signInOrAuthenticateTabView : Model -> Element Msg
signInOrAuthenticateTabView model =
    let
        ( bgCol1, bgCol2 ) =
            case model.page of
                RegisterPage ->
                    ( gray6, gray7 )

                SignInPage ->
                    ( gray7, gray6 )
    in
    row [ width fill, Region.heading 1, Font.size 32, Background.color gray6 ]
        [ el [ padding 8, width (Element.fillPortion 1), Background.color bgCol1 ]
            (Input.button [ centerX, width fill, height fill ]
                { onPress = Just (Go SignInPage)
                , label = text "Sign In"
                }
            )
        , el [ padding 8, width (Element.fillPortion 1), Background.color bgCol2 ]
            (Input.button [ centerX, width fill, height fill ]
                { onPress = Just (Go RegisterPage)
                , label = text "Register"
                }
            )
        ]


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
