# Spotify API Setup for TheDailyPoop

This guide explains how to set up Spotify API credentials for the music integration feature in TheDailyPoop app.

## Step 1: Create a Spotify Developer Account

1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Log in with your Spotify account or create a new one
3. Accept the Developer Terms of Service

## Step 2: Create a New App

1. Click the "Create an App" button
2. Fill in the required information:
   - **App Name**: TheDailyPoop
   - **App Description**: Music sharing in a social poop tracking app
   - **Redirect URI**: `thedailypoop://spotify-callback`
   - **Website**: (Optional) Your website or leave blank
3. Check "I understand and agree with Spotify's Developer Terms of Service"
4. Click "Create"

## Step 3: Get Your Credentials

1. After creating the app, you'll be redirected to the app dashboard
2. Here you'll find your **Client ID** and **Client Secret**
3. Keep these values secure - they are your app's credentials

## Step 4: Update the SpotifyAPIClient

1. Open `PoopDrop/Managers/SpotifyAPIClient.swift`
2. Replace the placeholder values with your actual credentials:

```swift
// MARK: - Replace these with your actual Spotify Developer credentials
private let clientID = "YOUR_CLIENT_ID" // Replace with your actual Client ID
private let clientSecret = "YOUR_CLIENT_SECRET" // Replace with your actual Client Secret
```

## Step 5: Configure URL Scheme (for User Authentication)

If you want to implement full user authentication later (not currently needed for basic functionality):

1. In Xcode, select your project in the Project Navigator
2. Select the app target and go to the "Info" tab
3. Expand "URL Types" and add a new one
4. Set the URL Scheme to `thedailypoop`

## Features Enabled by the Spotify API

With this integration, TheDailyPoop can:

1. **Search for tracks** using the Spotify catalog
2. **Retrieve track metadata** including:
   - Track name
   - Artist name(s)
   - Album artwork (high resolution)
   - External URLs
3. **Parse Spotify links** shared by users
4. **Display rich music cards** in the feed

## Troubleshooting

- If you see "Could not extract Spotify track information" errors, check that your Client ID and Secret are correctly entered
- For rate limiting issues, Spotify allows up to 1 request per second for search endpoints in the free tier
- For any other issues, check the [Spotify Developer Documentation](https://developer.spotify.com/documentation/web-api/)
