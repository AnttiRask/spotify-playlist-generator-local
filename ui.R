# Load required packages
library(conflicted)
library(plotly)
library(purrr)
library(shinydashboard)
library(shinythemes)
library(stringr)
library(waiter)

# Load scripts from the 'scripts' folder
source("scripts/global.R", local = TRUE)

# Define the UI function
fluidPage(
    
    # Automatically display a loading screen until UI is ready
    autoWaiter(),
    
    # Set the theme and custom CSS
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
                
                # User inputs for Spotify Developer credentials
                textInput("client_id", "Client ID: ", ""),
                passwordInput("client_secret", "Client Secret: ", ""),
                br(),
                
                # Button to validate the user's credentials
                actionButton("btn", "Validate"),
                br(),
                br(),
                
                # Output message after validation
                textOutput("validate_message")
            ),
            mainPanel(
                
                # Display welcome and instructions
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
        
        # Feature per Album tab
        tabPanel(
            "Feature per Album",
            sidebarPanel(
                h3("Features:"),
                
                # User selection of features to display
                selectInput(
                    "feature",
                    "Select a feature to view:",
                    choices  = features,
                    selected = "acousticness"
                ),
                
                # Introduction about the selected feature
                textOutput("feature_introduction")
            ),
            
            # Plotting area
            mainPanel(
                plotlyOutput("summary_plot", height = 700)
            )
        ),
        
        # Average Features tab
        tabPanel(
            "Average Features",
            div(
                class = "plot-center",
                
                # Plotting area
                mainPanel(plotOutput("artists_plot", height = 700)
                )
            )
        ),
        
        # Mood Quadrants tab
        tabPanel(
            "Mood Quadrants",
            sidebarPanel(
                h3("Features:"),
                
                # User selection for X and Y axis features
                selectInput(
                    "x_var",
                    "X Axis (Horizontal):",
                    choices  = features,
                    selected = "energy"
                ),
                selectInput(
                    "y_var",
                    "Y Axis (Vertical):",
                    choices  = features,
                    selected = "valence"
                )
            ),
            
            # Plotting area
            mainPanel(plotlyOutput("tracks_plot", height = 700)
            )
        ),
        
        # Playlist Generator tab
        tabPanel(
            "Playlist Generator",
            fluidPage(
                fluidRow(
                    column(4,
                           h3("Input:"),
                           br(),
                    ),
                    column(8,
                           h3("Targets:"),
                           br()
                    ),
                    column(3,
                           
                           # User inputs for Spotify username, number of top artists, and playlist name
                           textInput("user_id", "Spotify Username: ", ""),
                           numericInput("num_top_artists", "Number of top artists (1-5):", min = 1, max = 5, value = 5),
                           textInput("playlist_name", "Playlist Name: "),
                           br(),
                           
                           # Button to generate the playlist
                           actionButton("generate", "Generate Playlist")
                    ),
                    column(4,
                           # offset = 1,
                           
                           # User inputs for target feature values
                           sliderInput("acousticness", "Acousticness (0-1):", min = 0, max = 1, value = 0.5, step = 0.1),
                           sliderInput("danceability", "Danceability (0-1):", min = 0, max = 1, value = 0.5, step = 0.1),
                           sliderInput("energy", "Energy (0-1):", min = 0, max = 1, value = 0.5, step = 0.1)
                    ),
                    column(4,
                           
                           # User inputs for target feature values
                           sliderInput("instrumentalness", "Instrumentalness (0-1):", min = 0, max = 1, value = 0.5, step = 0.1),
                           sliderInput("speechiness", "Speechiness (0-1):", min = 0, max = 1, value = 0.5, step = 0.1),
                           sliderInput("valence", "Valence (0-1):", min = 0, max = 1, value = 0.5, step = 0.1)
                    ),
                    column(12,
                           br(),
                           
                           # Display the link to the generated playlist
                           uiOutput("playlist_link")
                    )
                )
            )
        )
    )
)