# Load packages
library(conflicted)
library(dplyr)
library(ggplot2)
library(ggrepel)
library(purrr)
library(shinydashboard)
library(spotifyr)
library(stringr)
library(tidyr)

# Server
server <- function(input, output, session) {
    
    conflict_prefer("filter", "dplyr")
    
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
            limit = 2,
            authorization = get_authorized("user-top-read")
        ) %>% 
            pull(name)
        
        # Fetch the track features for the top artists
        my_artists_track_features <- bind_rows(
            map(
                my_artists,
                get_artist_audio_features,
                market = "US"
            )
        ) %>% 
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
    
    my_album_summary_stats <- reactive({
        
        # Ensure that this reactive is only executed when the 'Validate' button is clicked
        req(input$btn)
        
        my_album_summary_stats <- my_artists_track_features() %>%
        summarise(
            across(where(is.numeric), mean),
            tracks = n(),
            .by    = c(artist_name, album_release_year, album_name)
        ) %>% 
        filter(
            liveness < 0.29,
            str_detect(tolower(album_name), "edition") == FALSE
        ) %>%
        mutate(
            album_number = row_number(album_release_year),
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
    
    # Summary Insights ----
    output$summary_plot <- renderPlot({
        
        my_album_summary_stats() %>% 
            ggplot(aes(album_number, score, color = artist_name)) + 
            geom_line() +
            geom_point() +
            facet_wrap(
                vars(feature),
                ncol = 2,
                scales = "free_y"
            ) +
            labs(
                x = "Album #",
                y = "Score"
            ) +
            theme_classic()
    })
    
    # Top Artists ----
    output$artists_plot <- renderPlot({
        
        my_artists_track_features() %>% 
            pivot_longer(
                cols = !c(
                    track_name,
                    artist_name,
                    album_release_year,
                    album_name,
                    track_id,
                    artist_id
                ),
                names_to  = "feature",
                values_to = "score"
            ) %>% 
            filter(
                feature %in% c(
                    "danceability",
                    "energy",
                    "valence"
                )
            ) %>%
            ggplot(aes(feature %>% str_to_title(), score, color = artist_name)) +
            geom_boxplot(
                fill      = spotify_colors$black,
                linewidth = 1
            ) +
            labs(
                color = "Artist",
                title = "Artists' Average Scores on Music Features",
                x     = NULL,
                y     = "Score"
            ) +
            scale_color_manual(values = monokai_palette) +
            theme_spotify()
        
    })
    
    # Top Tracks ----
    output$tracks_plot <- renderPlot({
        
        top_tracks <- bind_rows(
            map(unique(my_artists_track_features()$artist_id), get_artist_top_tracks)
        )
        
        top_tracks %>% 
            select(id, popularity) %>%
            right_join(
                my_artists_track_features(),
                by = join_by(id == track_id)
            ) %>%
            mutate(
                rank_top_song = row_number(desc(popularity)),
                .by = artist_name
            ) %>%
            ggplot(aes(energy, valence, color = artist_name)) +
            geom_point() +
            geom_label_repel(
                aes(
                    label = case_when(
                        rank_top_song <= 3 ~ track_name,
                        TRUE ~ NA_character_
                    )
                )
            ) + 
            geom_hline(yintercept = 0.5,  color = "grey", linetype = "dashed") +
            geom_vline(xintercept = 0.5,  color = "grey", linetype = "dashed") +
            annotate("text", 0.25 / 2, 1, label = "Hopeful Ballads",  fontface = "italic") +
            annotate("text", 1.75 / 2, 1, label = "Vibrant Cheerful", fontface = "italic") +
            annotate("text", 1.75 / 2, 0, label = "Vibrant Enraged",  fontface = "italic") +
            annotate("text", 0.25 / 2, 0, label = "Sad Ballads",      fontface = "italic") +
            labs(
                x     = "Energy",
                y     = "Valence",
                color = "Artist",
                title = "Songs mood"
            ) +
            theme_classic()
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
        my_happy_and_energetic_songs <- get_recommendations(
            seed_artists = head(my_top_artists, input$num_top_artists) %>% pull(id),
            min_energy   = input$energy,
            min_valence  = input$valence
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
            uris          = my_happy_and_energetic_songs$id,
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