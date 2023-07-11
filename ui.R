# Load packages
library(conflicted)
library(plotly)
library(purrr)
library(shinydashboard)
library(shinythemes)
library(stringr)
library(waiter)

source("scripts/global.R", local = TRUE)

# Define UI
fluidPage(
    autoWaiter(),
    theme = shinytheme("cyborg"),
    includeCSS("css/styles.css"),
    navbarPage(
        
        # Application title
        title = list(
            icon(
                "spotify",
                lib = "font-awesome"
            ),
            "Spotify Playlist Generator"
        ),
        
        # Authentication tab
        tabPanel(
            "Intro",
            sidebarPanel(
                h3("Input:"),
                br(),
                textInput("client_id", "Client ID: ", ""),
                passwordInput("client_secret", "Client Secret: ", ""),
                br(),
                actionButton("btn", "Validate"),
                br(),
                br(),
                textOutput("validate_message")
            ),
            mainPanel(
                h2("Welcome to the Spotify Playlist Generator"),
                br(),
                h6("You can use this tool to see different analyses on your favorite music on Spotify. You can even create new playlists that use your favorites as a starting point!"),
                br(),
                h6("But first, here are some prerequisites:"),
                h6("Step 1: Login to ", tags$a(href = "https://developer.spotify.com/dashboard/", "https://developer.spotify.com/dashboard/"), " with your Spotify credentials"),
                h6("Step 2: 'Create' a temp app (the Redirect URIs needs to be http://localhost:1410/)"),
                h6("Step 3: In the app Settings, find the Client ID and Client Secret. Copy and paste them into the input boxes on the left with your Spotify username and click Validate"),
                h6("Step 4: Allow spotify to authenticate your account"),
                br(),
                h6("You should be good to go! Click any of the tabs above to get started."),
            )
        ),
        
        # Average Features tab
        tabPanel(
            "Average Features",
            div(
                class = "plot-center",
                mainPanel(plotOutput("artists_plot", height = 700)
                )
            )
        ),
        
        # Feature per Album tab
        tabPanel(
            "Feature per Album",
            div(
                class = "plot-center",
                mainPanel(
                    plotOutput("summary_plot", height = 700),
                    selectInput(
                        "feature",
                        "Select a feature to view:",
                        choices  = features,
                        selected = "energy"
                    ),
                )
            )
        ),
        
        # Mood Quadrants tab
        tabPanel(
            "Mood Quadrants",
            div(
                class = "plot-center",
                mainPanel(plotlyOutput("tracks_plot", height = 700)
                )
            )
        ),
        
        # Playlist Generator tab
        tabPanel(
            "Playlist Generator",
            sidebarPanel(
                h3("Input:"),
                br(),
                textInput("user_id", "Spotify Username: ", ""),
                numericInput("num_top_artists", "Number of top artists (1-5):", min = 1, max = 5, value = 5),
                textInput("playlist_name", "Playlist Name: "),
                hr(),
                h4("Targets:"),
                sliderInput("acousticness", "Acousticness (0-1):", min = 0, max = 1, value = 0.5, step = 0.1),
                sliderInput("danceability", "Danceability (0-1):", min = 0, max = 1, value = 0.5, step = 0.1),
                sliderInput("energy", "Energy (0-1):", min = 0, max = 1, value = 0.5, step = 0.1),
                sliderInput("instrumentalness", "Instrumentalness (0-1):", min = 0, max = 1, value = 0.5, step = 0.1),
                sliderInput("speechiness", "Speechiness (0-1):", min = 0, max = 1, value = 0.5, step = 0.1),
                sliderInput("valence", "Valence (0-1):", min = 0, max = 1, value = 0.5, step = 0.1),
                br(),
                actionButton("generate", "Generate Playlist")
            ),
            mainPanel(
                uiOutput("playlist_link")
            )
        )
    )
)