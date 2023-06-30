# The function for getting the Spotify authorization code
get_authorized <- function(.scope) {
    
    get_spotify_authorization_code(
        client_id     = input$client_id,
        client_secret = input$client_secret,
        scope         = .scope
    )
}