features <- c(
    "acousticness",
    "danceability",
    "energy",
    "instrumentalness",
    "speechiness",
    "valence"
)

monokai_palette <- c(
    "#F92672",
    "#FD971F",
    "#F4BF75",
    "#A6E22E",
    "#A1EFE4",
    "#66D9EF",
    "#AE81FF",
    "#CC6633"
)

spotify_colors <- list(
    dark_green  = "#1DB954",
    light_green = "#1ed760",
    black       = "#191414",
    light_grey  = "#b3b3b3",
    white       = "#FFFFFF"
)

theme_spotify <- function(){
    color.background = spotify_colors$black
    color.grid.major = spotify_colors$white
    color.text       = spotify_colors$dark_green
    color.text.2     = spotify_colors$light_green
    color.axis       = spotify_colors$white
    
    theme_bw(base_size = 20, base_family = "Gotham") +
        
        theme(
            # Axis
            axis.line.x  = element_line(color = color.grid.major, linewidth = 1),
            axis.line.y  = element_line(color = color.grid.major, linewidth = 1),
            axis.text.x  = element_text(size  = rel(0.95), color = color.text),
            axis.text.y  = element_text(size  = rel(0.95), color = color.text),
            axis.ticks   = element_line(color = NA),
            axis.title.x = element_text(size  = rel(1), color = color.text, vjust = 0),
            axis.title.y = element_text(size  = rel(1), color = color.text, vjust = 1.25),
            
            # Legend
            legend.background = element_rect(fill  = color.background),
            legend.key        = element_rect(fill  = color.background, color = NA),
            legend.text       = element_text(size  = rel(0.8), color = color.text.2),
            legend.title      = element_text(color = color.text, face = "bold"),
            
            # Panel
            panel.background   = element_rect(
                fill  = color.background,
                color = color.background
            ),
            panel.border       = element_rect(color = color.background),
            panel.grid.major   = element_line(
                color     = color.grid.major,
                linewidth = 0.4,
                linetype  = 2
            ),
            panel.grid.major.x = element_blank(),
            panel.grid.minor   = element_blank(),
            
            # Plot
            plot.background = element_rect(fill = color.background, color = color.background),
            plot.title      = element_text(
                color = color.text,
                size  = rel(1.2),
                hjust = 0.5,
                face  = "bold"
            )
        )
}