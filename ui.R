# Load packages
library(conflicted)
library(shinydashboard)
library(shinythemes)

# Define UI
fluidPage(
    theme = shinytheme("cyborg"),
    includeCSS("css/styles.css"),
    navbarPage(
        
        # Application title
        "Spotify Playlist Generator",
        
        # Authentication tab
        tabPanel(
            "Intro",
            sidebarPanel(
                h3("Input:"),
                textInput("client_id", "Client ID: ", ""),
                passwordInput("client_secret", "Client Secret: ", ""),
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
        
        # Summary Insights tab
        tabPanel(
            "Summary Insights",
            mainPanel(
                plotOutput("summary_plot") # Summary insights plot output
            )
        ),
        
        # Top Artists tab
        tabPanel(
            "Top Artists",
            mainPanel(
                plotOutput("artists_plot") # Top artists plot output
            )
        ),
        
        # Top Tracks tab
        tabPanel(
            "Top Tracks",
            mainPanel(
                plotOutput("tracks_plot") # Top tracks plot output
            )
        ),

        # Playlist Generator tab
        tabPanel(
            "Playlist Generator",
            sidebarPanel(
                h3("Input:"),
                textInput("user_id", "Spotify Username: ", ""),
                numericInput("num_top_artists", "Number of top artists (1-5):", min = 1, max = 5, value = 5),
                numericInput("energy", "Minimum energy (0-1):", min = 0, max = 1, value = 0.6),
                numericInput("valence", "Minimum valence (0-1):", min = 0, max = 1, value = 0.6),
                textInput("playlist_name", "Playlist Name: "),
                actionButton("generate", "Generate Playlist")
            ),
            mainPanel(
                uiOutput("playlist_link")
            )
        )
    ) 
)