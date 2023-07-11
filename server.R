# Load packages
library(conflicted)
library(dplyr)
library(forcats)
library(ggplot2)
library(ggrepel)
library(plotly)
library(purrr)
library(shinydashboard)
library(spotifyr)
library(stringr)
library(tidyr)
library(waiter)

# Server
server <- function(input, output, session) {
    
    conflict_prefer("filter", "dplyr")
    # conflict_prefer("layout", "plotly")
    
    options(httr_oauth_cache = FALSE) # Disable OAuth caching
    
    source("scripts/functions.R", local = TRUE)
    source("scripts/global.R", local = TRUE)
    
    observeEvent(input$btn, {
        
        # Authentication
        Sys.setenv(SPOTIFY_CLIENT_ID     = input$client_id)
        Sys.setenv(SPOTIFY_CLIENT_SECRET = input$client_secret)
        
        access_token <- get_spotify_access_token()
        
        # Check if access_token_result is a list and if it has access_token in it
        if (nzchar(access_token)) {
            output$validate_message <- renderText("Validation Successful!")
        } else {
            output$validate_message <- renderText("Validation Failed!")
        }
        
    })
    
    my_artists_track_features <- reactive({
        
        # Ensure that this reactive is only executed when the 'Validate' button is clicked
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
    
    # Average Features ----
    output$artists_plot <- renderPlot({
        
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
                panel.grid.minor   = element_blank(),
            )
    })
    
    my_album_summary_stats <- reactive({
        
        my_album_summary_stats <- my_artists_track_features() %>%
            summarise(
                across(where(is.numeric), mean),
                .by    = c(artist_name, album_release_year, album_name)
            ) %>%
            # Get rid off the live albums and/or special editions
            filter(
                liveness < 0.29,
                str_detect(tolower(album_name), "edition") == FALSE
            ) %>%
            mutate(
                album_number = row_number(),
                .by = artist_name
            ) %>%
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
    
    # Feature per Album ----
    output$summary_plot <- renderPlot({
        
        my_album_summary_stats() %>% 
            filter(feature == input$feature) %>%
            ggplot(aes(album_number, score, color = artist_name)) + 
            geom_line(linewidth = 1) +
            geom_point(size = 4) +
            labs(
                color = "Artist",
                title = str_glue("Average {str_to_title(input$feature)} per Album"),
                x     = "Album #",
                y     = NULL
            ) +
            scale_color_manual(values = monokai_palette) +
            theme_spotify()
    })
    
    # Mood Quadrants ----
    output$tracks_plot <- renderPlotly({
        
        top_tracks <- bind_rows(
            map(unique(my_artists_track_features()$artist_id), get_artist_top_tracks)
        )
        
        # Create a ggplot object
        p <- top_tracks %>%
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
                    Energy: {round(energy, 2)}
                    Valence: {round(valence, 2)}"
                )
            ) %>%
            ggplot(aes(energy, valence, color = artist_name)) +
            geom_point(aes(text = label_text), alpha = 0.9) +
            geom_hline(yintercept = 0.5,  color = "grey", linetype = "dashed") +
            geom_vline(xintercept = 0.5,  color = "grey", linetype = "dashed") +
            labs(
                x     = "Energy",
                y     = "Valence",
                color = "Artist",
                title = "Songs mood"
            ) +
            scale_color_manual(values = monokai_palette) +
            theme_spotify() +
            theme(panel.grid.major = element_blank())
        
        # Convert it to a plotly object
        p <- ggplotly(p, tooltip = "text")
        
        # Add annotations (quadrant labels) using layout
        p <- p %>%
            plotly::layout(
                annotations = list(
                    list(
                        x           = 1,
                        y           = 0,
                        text        = "Sad Bangers",
                        bordercolor = spotify_colors$dark_green,
                        font        = list(
                            color  = spotify_colors$dark_green,
                            family = "Gotham",
                            size   = 15
                        ),
                        showarrow = FALSE
                    ),
                    list(
                        x           = 1,
                        y           = 1,
                        text        = "Happy Bangers",
                        bordercolor = spotify_colors$dark_green,
                        font        = list(
                            color  = spotify_colors$dark_green,
                            family = "Gotham",
                            size   = 15
                        ),
                        showarrow   = FALSE
                    ),
                    list(
                        x           = 0.1,
                        y           = 1,
                        text        = "Happy Ballads",
                        bordercolor = spotify_colors$dark_green,
                        font        = list(
                            color  = spotify_colors$dark_green,
                            family = "Gotham",
                            size   = 15
                        ),
                        showarrow   = FALSE
                    ),
                    list(
                        x           = 0.07,
                        y           = 0,
                        text        = "Sad Ballads",
                        bordercolor = spotify_colors$dark_green,
                        font        = list(
                            color = spotify_colors$dark_green,
                            font  = "Gotham",
                            size  = 15
                        ),
                        showarrow   = FALSE
                    )
                ),
                legend = list(
                    bordercolor = spotify_colors$dark_green,
                    borderwidth = 1,
                    font        = list(
                        color = spotify_colors$dark_green,
                        font  = "Gotham",
                        size  = 20
                    ),
                    x = 1.1,
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
        
        return(p)
    })
    
    # Playlist Generator ----
    observeEvent(input$generate, {
        
        req(input$client_id, input$client_secret, input$user_id)
        
        # Get top artists
        my_top_artists <- get_my_top_artists_or_tracks(
            type          = "artists", 
            limit         = input$num_top_artists,  
            time_range    = "medium_term",
            authorization = get_authorized("user-top-read")
        )
        
        # Get song recommendations
        new_playlist <- get_recommendations(
            seed_artists            = head(my_top_artists, input$num_top_artists) %>% pull(id),
            target_acousticness     = input$acousticness,
            target_danceability     = input$danceability,
            target_energy           = input$energy,
            target_instrumentalness = input$instrumentalness,
            target_speechiness      = input$speechiness,
            target_valence          = input$valence
        )
        
        # Create an empty playlist
        playlist_id <- create_playlist(
            user_id       = input$user_id,
            name          = str_glue("{input$playlist_name} ({Sys.Date()})"),
            description   = "Generated with R!",
            authorization = get_authorized("playlist-modify-public")
        )$id
        
        # Populate the created playlist
        add_tracks_to_playlist(
            playlist_id   = playlist_id,
            uris          = new_playlist$id,
            authorization = get_authorized("playlist-modify-public")
        )
        
        output$playlist_link <- renderUI({
            playlist_link <- str_glue("https://open.spotify.com/playlist/{playlist_id}")
            p("The playlist was created. Here is the ", a("link.", href = playlist_link, target="_blank"))
        })
    })
    
    session$onSessionEnded(function() {
        Sys.unsetenv("SPOTIFY_CLIENT_ID")
        Sys.unsetenv("SPOTIFY_CLIENT_SECRET")
    })
}