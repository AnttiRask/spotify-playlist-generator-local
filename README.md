# Spotify: Favorite Artist Analyzer and Playlist Generator :musical_notes:

This app uses the Spotify API to...

* fetch 2 random artists from users' top 20 artists
* visualize and compare
    * average features per album
    * average features per artist
    * mood quadrants (scatterplot between two features)
* create new playlists
    * using user's top (1-5) artists as seed
    * choosing features (0-1) as targets


## How it started:

The inspiration for this project came from R User Group Helsinki's [workshop](https://github.com/eivicent/r-meetups-hki/tree/main/2023_03_28_SpotifyR) in March 2023. We learned to use the [Spotify API](https://developer.spotify.com/documentation/web-api) using the {spotifyr} package.

I used some of the original functions, but also came up with some new ones. The biggest change, though, was creating a Shiny app to combine the different functions as a coherent whole.


## How it's going:

If you want to, you can try the app yourself by...

1. forking your own copy of the repo and cloning it
2. logging into [Spotify Developer dashboard](https://developer.spotify.com/dashboard/) with your Spotify credentials
3. 'creating' a temp app (the Redirect URIs needs to be http://localhost:1410/)
4. finding the Client ID and Client Secret from the app settings. Copy and paste them into the input boxes on the left with your Spotify username and click Validate
5. allowing Spotify to authenticate your account


## How it works:

The repo is broken into three parts:

1. UI
2. Server
3. Running the app

### 1. UI

I'm using...

* a Shiny theme ('cyborg') that has been customized using a separate style sheet (CSS)
* a [Font Awesome](https://fontawesome.com/) icon for the Spotify icon in the title
* autoWaiter() function from {waiter} to create the loading animations
* a lot of different inputs (text, password, select, slider)

### 2. Server

We're...
* observing
    * the button click event for authentication
    * available choices for y when x changes (since the two shouldn't be the same in a scatterplot)
    * the click event on the 'generate' button to generate a playlist
* getting and validating the Spotify access token
* defining reactive expression to...
    * fetch top 20 artists and their track features
    * summarize album track features
    * provide feature descriptions
    * create a summary plot
    * create an artist feature plot
    * create a mood quadrants plot
* randomly selecting two of those artists to display on the app
* using the Gotham font family, because it's the closest to the official Spotify font
* converting the {ggplot2} plots to {plotly} for interactivity

### 3. Running the app

This is really straightforward, just run the run.R script. It will take care of the rest.

## What next?

The next step is to create a version of the app that is deployed on a ShinyApps server. The biggest challenge with that is the Spotify API authorization that is much more complicated than in this locally run version.

Is there something you would like to see? Let me know!
