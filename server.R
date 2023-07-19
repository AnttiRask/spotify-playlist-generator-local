# Load necessary packages
library(conflicted)
library(dplyr)
library(extrafont)
library(forcats)
library(ggplot2)
library(plotly)
library(purrr)
library(shinydashboard)
library(spotifyr)
library(stringr)
library(tidyr)
library(waiter)

# Define the server function
server <- function(input, output, session) {
    
    # Define the preferred 'filter' function to avoid namespace clashes
    conflict_prefer("filter", "dplyr")
    
    # Disable OAuth caching for the 'httr' package
    options(httr_oauth_cache = FALSE)
    
    # Load helper functions and global variables from local R scripts
    source("scripts/functions.R", local = TRUE)
    source("scripts/global.R", local = TRUE)
    
    # Observe button click event for authentication
    observeEvent(input$btn, {
        
        # Set environment variables for Spotify API credentials
        Sys.setenv(SPOTIFY_CLIENT_ID     = input$client_id)
        Sys.setenv(SPOTIFY_CLIENT_SECRET = input$client_secret)
        
        # Get Spotify access token
        access_token <- get_spotify_access_token()
        
        # Check if access token is valid and display validation status
        if (nzchar(access_token)) {
            output$validate_message <- renderText("Validation Successful!")
        } else {
            output$validate_message <- renderText("Validation Failed!")
        }
        
    })
    
    # Define reactive expression to fetch top artists and their track features
    my_artists_track_features <- reactive({
        
        # Ensure reactive expression is only executed when 'Validate' button is clicked
        req(input$btn)
        
        # Fetch the top artists for the authenticated user
        my_artists <- get_my_top_artists_or_tracks(
            limit         = 20,
            authorization = get_authorized("user-top-read")
        ) %>%
            slice_sample(n = 2) %>% 
            pull(name)
        
        # Fetch the track features for the top artists
        my_artists_track_features <- map(
            my_artists,
            get_artist_audio_features,
            market = "US"
        ) %>%
            bind_rows() %>% 
            select(
                artist_id,
                artist_name,
                track_id,
                track_name,
                album_name,
                album_release_year,
                acousticness,
                danceability,
                energy,
                instrumentalness,
                liveness,
                speechiness,
                valence
            ) %>%
            as_tibble()
        
        return(my_artists_track_features)
    })
    
    # Define reactive expression to summarize album track features
    my_album_summary_stats <- reactive({
        
        my_album_summary_stats <- my_artists_track_features() %>%
            summarise(
                across(where(is.numeric), mean),
                .by    = c(artist_name, album_release_year, album_name)
            ) %>%
            filter(
                str_detect(tolower(album_name), "commentary version") == FALSE,
                str_detect(tolower(album_name), "deluxe edition") == FALSE,
                str_detect(tolower(album_name), "track commentary") == FALSE
            ) %>%
            group_by(artist_name) %>%
            arrange(artist_name, album_release_year, album_name) %>%
            mutate(album_number = row_number(album_release_year)) %>%
            ungroup() %>%
            pivot_longer(
                cols      = !c(artist_name, album_release_year, album_name, album_number),
                names_to  = "feature",
                values_to = "score"
            ) %>%
            filter(
                feature %in% features
            )
        
        return(my_album_summary_stats)
        
    })
    
    # Define reactive expression to provide feature descriptions
    output$feature_introduction <- renderText({
        
        # Return feature description based on selected feature
        if (input$feature == "acousticness") {
            return('"A confidence measure from 0.0 to 1.0 of whether the track is acoustic. 1.0 represents high confidence the track is acoustic." -Spotify'
            )
        }
        
        if (input$feature == "danceability") {
            return('"Danceability describes how suitable a track is for dancing based on a combination of musical elements including tempo, rhythm stability, beat strength, and overall regularity. A value of 0.0 is least danceable and 1.0 is most danceable." -Spotify')
        }
        
        if (input$feature == "energy") {
            return('"Energy is a measure from 0.0 to 1.0 and represents a perceptual measure of intensity and activity. Typically, energetic tracks feel fast, loud, and noisy. For example, death metal has high energy, while a Bach prelude scores low on the scale. Perceptual features contributing to this attribute include dynamic range, perceived loudness, timbre, onset rate, and general entropy." -Spotify')
        }
        
        if (input$feature == "instrumentalness") {
            return('"Predicts whether a track contains no vocals. "Ooh" and "aah" sounds are treated as instrumental in this context. Rap or spoken word tracks are clearly "vocal". The closer the instrumentalness value is to 1.0, the greater likelihood the track contains no vocal content. Values above 0.5 are intended to represent instrumental tracks, but confidence is higher as the value approaches 1.0." -Spotify')
        }
        
        if (input$feature == "speechiness") {
            return('"Speechiness detects the presence of spoken words in a track. The more exclusively speech-like the recording (e.g. talk show, audio book, poetry), the closer to 1.0 the attribute value. Values above 0.66 describe tracks that are probably made entirely of spoken words. Values between 0.33 and 0.66 describe tracks that may contain both music and speech, either in sections or layered, including such cases as rap music. Values below 0.33 most likely represent music and other non-speech-like tracks." -Spotify')
        }
        
        if (input$feature == "valence") {
            return('"A measure from 0.0 to 1.0 describing the musical positiveness conveyed by a track. Tracks with high valence sound more positive (e.g. happy, cheerful, euphoric), while tracks with low valence sound more negative (e.g. sad, depressed, angry)." -Spotify')
        }
        
    })
    
    # Define reactive expression to create a summary plot
    output$summary_plot <- renderPlotly({
        
        # Create ggplot, then convert it to plotly for interactive plots
        plot1 <- my_album_summary_stats() %>%
            mutate(label_text = str_glue("{album_name} ({album_release_year})")) %>%
            filter(feature == input$feature) %>%
            ggplot(aes(album_number, score, color = artist_name)) + 
            geom_line(linewidth = 1) +
            geom_point(aes(text = label_text), size = 2) +
            labs(
                color = "Artist",
                title = str_glue("Average {str_to_title(input$feature)} per Album"),
                x     = "Album #",
                y     = NULL
            ) +
            scale_color_manual(values = monokai_palette) +
            theme_spotify()
        
        plot1 <- ggplotly(plot1, tooltip = "text")
        
        plot1 <- plot1 %>%
            plotly::layout(
                legend = list(
                    font        = list(
                        color = spotify_colors$dark_green,
                        font  = "Gotham",
                        size  = 20
                    ),
                    x = 1.05,
                    y = 0.5
                ), 
                xaxis = list(
                    autorange = TRUE
                )
            )
        
        return(plot1)
        
    })
    
    # Define reactive expression to create artist feature plot
    output$artists_plot <- renderPlot({
        
        # Create ggplot to show average values of different features per artist
        my_artists_track_features() %>%
            select(
                -c(
                    track_name,
                    album_release_year,
                    album_name,
                    track_id,
                    artist_id
                )
            ) %>%
            pivot_longer(
                cols = !c(artist_name),
                names_to        = "feature",
                values_to       = "score",
                names_transform = list(feature = as.factor)
            ) %>% 
            filter(feature %in% features) %>%
            ggplot(aes(feature %>% str_to_title() %>% fct_rev(), score, color = artist_name)) +
            geom_boxplot(
                fill      = spotify_colors$black,
                linewidth = 1
            ) +
            coord_flip() +
            labs(
                color = "Artist",
                title = "Average Values of Different Features (0-1)",
                x     = NULL,
                y     = NULL
            ) +
            scale_color_manual(values = monokai_palette) +
            theme_spotify() +
            theme(
                panel.grid.major.x = element_line(
                    color     = spotify_colors$white,
                    linewidth = 0.4,
                    linetype  = 2
                ),
                panel.grid.major.y = element_blank(),
                panel.grid.minor   = element_blank()
            )
    })
    
    # Update available y_var choices when x_var changes
    observe({
        if (!is.null(input$x_var)) {
            updateSelectInput(
                session, "y_var",
                choices  = setdiff(features, input$x_var),
                selected = "valence"
            )
        }
    })
    
    # Define reactive expression to create mood quadrants plot
    output$tracks_plot <- renderPlotly({
        
        req(input$x_var, input$y_var)
        
        top_tracks <- bind_rows(
            map(unique(my_artists_track_features()$artist_id), get_artist_top_tracks)
        )
        
        # Create ggplot, then convert it to plotly for interactive plots
        plot2 <- top_tracks %>%
            select(id, popularity) %>%
            right_join(
                my_artists_track_features(),
                by = join_by(id == track_id)
            ) %>%
            mutate(
                rank_top_song = row_number(desc(popularity)),
                .by = artist_name
            ) %>%
            mutate(
                label_text = str_glue(
                    "{track_name}
                    from {album_name} ({album_release_year})
                    {str_to_title(input$x_var)}: {round(.data[[input$x_var]], 2)}
                    {str_to_title(input$y_var)}: {round(.data[[input$y_var]], 2)}"
                )
            ) %>%
            ggplot(aes(.data[[input$x_var]], .data[[input$y_var]], color = artist_name)) +
            geom_point(aes(text = label_text), alpha = 0.9) +
            geom_hline(yintercept = 0.5,  color = "grey", linetype = "dashed") +
            geom_vline(xintercept = 0.5,  color = "grey", linetype = "dashed") +
            labs(
                x     = str_to_title(input$x_var),
                y     = str_to_title(input$y_var),
                color = "Artist",
                title = "Mood Quadrants"
            ) +
            scale_color_manual(values = monokai_palette) +
            theme_spotify() +
            theme(panel.grid.major = element_blank())
        
        plot2 <- ggplotly(plot2, tooltip = "text")
        
        plot2 <- plot2 %>%
            plotly::layout(
                legend = list(
                    font        = list(
                        color = spotify_colors$dark_green,
                        font  = "Gotham",
                        size  = 20
                    ),
                    x = 1.05,
                    y = 0.5
                ), 
                xaxis  = list(
                    range    = c(0, 1),
                    showline = FALSE
                ), 
                yaxis  = list(
                    range    = c(0, 1),
                    showline = FALSE
                )
            )
        
        return(plot2)
    })
    
    # Listen for a click event on the 'generate' button to generate a playlist
    observeEvent(input$generate, {
        
        # Ensure that the necessary inputs are provided
        req(input$client_id, input$client_secret, input$user_id)
        
        # Get top artists for the authenticated user
        my_top_artists <- get_my_top_artists_or_tracks(
            type          = "artists", 
            limit         = input$num_top_artists,  
            time_range    = "medium_term",
            authorization = get_authorized("user-top-read")
        )
        
        # Get song recommendations based on user input and top artists
        new_playlist <- get_recommendations(
            seed_artists            = head(my_top_artists, input$num_top_artists) %>% pull(id),
            target_acousticness     = input$acousticness,
            target_danceability     = input$danceability,
            target_energy           = input$energy,
            target_instrumentalness = input$instrumentalness,
            target_speechiness      = input$speechiness,
            target_valence          = input$valence
        )
        
        # Create a new playlist for the authenticated user
        playlist_id <- create_playlist(
            user_id       = input$user_id,
            name          = str_glue("{input$playlist_name} ({Sys.Date()})"),
            description   = "Generated with R!",
            authorization = get_authorized("playlist-modify-public")
        )$id
        
        # Add recommended songs to the created playlist
        add_tracks_to_playlist(
            playlist_id   = playlist_id,
            uris          = new_playlist$id,
            authorization = get_authorized("playlist-modify-public")
        )
        
        # Render a UI element to display the playlist link
        output$playlist_link <- renderUI({
            playlist_link <- str_glue("https://open.spotify.com/playlist/{playlist_id}")
            p("The playlist was created. Here is the ", a("link.", href = playlist_link, target="_blank"))
        })
    })
    
    # Clear the SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET environment variables when the session ends
    session$onSessionEnded(function() {
        Sys.unsetenv("SPOTIFY_CLIENT_ID")
        Sys.unsetenv("SPOTIFY_CLIENT_SECRET")
    })
}
