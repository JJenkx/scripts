#!/home/jjenkx/.local/mypythonenvs/like.spotify

# python -m venv /home/jjenkx/.local/mypythonenvs/like.spotify
# pip install Flask pyglet spotipy

import spotipy
from spotipy.oauth2 import SpotifyOAuth
from flask import Flask, request, redirect
import os
import webbrowser
import socket
import threading
import time
import pyglet

# Spotify API credentials
CLIENT_ID = "myidkey"
CLIENT_SECRET = "myidsecret"
REDIRECT_URI = "http://localhost:8888/callback"

# Scopes needed for liking a song and modifying playlists
SCOPE = "user-library-modify user-read-playback-state playlist-modify-private playlist-modify-public"
CACHE_PATH = "/home/jjenkx/.cache-spotify"
#CACHE_PATH = "~/.cache"


# Flask app to handle the callback
app = Flask(__name__)
token_info = None

# Create the OAuth object
sp_oauth = SpotifyOAuth(client_id=CLIENT_ID,
                        client_secret=CLIENT_SECRET,
                        redirect_uri=REDIRECT_URI,
                        scope=SCOPE,
                        cache_path=CACHE_PATH)

@app.route('/')
def index():
    return 'Spotify Authorization Server is running. Visit /login to authorize the app.'

@app.route('/login')
def login():
    auth_url = sp_oauth.get_authorize_url()
    return redirect(auth_url)

@app.route('/callback')
def callback():
    global token_info
    code = request.args.get('code')
    if code:
        # Exchange the authorization code for an access token
        token_info = sp_oauth.get_access_token(code, as_dict=False)
        print(f"Token info retrieved in callback: {token_info}")  # Debugging log
        shutdown_server()
        return 'Authorization successful! You can close this window and return to your terminal.'
    else:
        return 'Error: No code provided.'

def is_port_in_use(port):
    """ Check if a port is in use """
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(('localhost', port)) == 0

def run_flask_server():
    """ Start the Flask server in a separate thread """
    app.run(port=8888)

def shutdown_server():
    """ Shuts down the Flask development server """
    func = request.environ.get('werkzeug.server.shutdown')
    if func:
        func()

def get_token():
    global token_info
    token_info = sp_oauth.get_cached_token()

    if not token_info:
        print("No valid token found, logging in...")

        # Check if Flask server is already running on port 8888
        if is_port_in_use(8888):
            print("Flask server is already running. Opening browser to login.")
            webbrowser.open("http://localhost:8888/login")
        else:
            # If not running, start the Flask server in a new thread and open the login page
            print("Starting new Flask server on port 8888...")
            threading.Thread(target=run_flask_server).start()
            webbrowser.open("http://localhost:8888/login")

        # Short wait for token to be retrieved
        max_wait = 60  # Maximum wait of 60 seconds
        start_time = time.time()

        while time.time() - start_time < max_wait:
            token_info = sp_oauth.get_cached_token()
            if token_info:
                print(f"Token info reloaded: {token_info}")  # Debugging log
                break
            time.sleep(1)

        if not token_info:
            print("Timeout waiting for the token. Exiting.")

    return token_info

def is_song_in_playlist(sp, playlist_id, track_id):
    """ Check if the track is already in the playlist (handle pagination) """
    offset = 0
    while True:
        results = sp.playlist_items(playlist_id, fields="items(track(id)),next", limit=100, offset=offset)
        tracks = results['items']

        for item in tracks:
            if item['track']['id'] == track_id:
                return True
        
        if results['next']:
            offset += len(tracks)
        else:
            break

    return False

def is_user_playlist(sp, playlist_id, user_id):
    """ Check if the playlist is owned by the current user """
    playlist = sp.playlist(playlist_id)
    return playlist['owner']['id'] == user_id

def show_overlay(message, duration=1):
    """ Show a floating text overlay with pyglet for a specified duration """
    print(f"Displaying overlay: {message}")

    window = pyglet.window.Window(width=2560, height=200, style=pyglet.window.Window.WINDOW_STYLE_OVERLAY)
    window.set_location(0, 600)

    label = pyglet.text.Label(message,
                              font_name='Helvetica',
                              font_size=48,
                              x=window.width // 2, y=window.height // 2,
                              anchor_x='center', anchor_y='center',
                              color=(39, 245, 123, 255))

    def close(dt):
        print("Closing overlay window...")
        window.close()

    pyglet.clock.schedule_once(close, duration)

    @window.event
    def on_draw():
        window.clear()
        label.draw()

    print("Running pyglet event loop...")
    pyglet.app.run()

if __name__ == '__main__':
    # Get token (will redirect user to log in if needed)
    token_info = get_token()

    if token_info and 'access_token' in token_info:
        sp = spotipy.Spotify(auth=token_info['access_token'])

        try:
            # Get the currently playing track and context (playlist, album, etc.)
            current_playback = sp.current_playback()

            if current_playback and current_playback['is_playing']:
                track_id = current_playback['item']['id']
                track_name = current_playback['item']['name']
                artist_names = ', '.join([artist['name'] for artist in current_playback['item']['artists']])

                # Add the track to "Liked Songs"
                sp.current_user_saved_tracks_add([track_id])
                print(f"Liked: {track_name} by {artist_names}")

                added_to_playlist = False

                # Check if the current track is playing from a playlist
                if current_playback['context'] and current_playback['context']['type'] == 'playlist':
                    playlist_uri = current_playback['context']['uri']
                    playlist_id = playlist_uri.split(':')[-1]

                    # Get current user ID
                    user_id = sp.current_user()['id']

                    # Check if the playlist is owned by the current user
                    if is_user_playlist(sp, playlist_id, user_id):
                        if not is_song_in_playlist(sp, playlist_id, track_id):
                            sp.playlist_add_items(playlist_id, [track_id])
                            print(f"Added {track_name} by {artist_names} to the current playlist.")
                            show_overlay(f"Added: {track_name}, {artist_names}", duration=3)
                            added_to_playlist = True
                        else:
                            print(f"{track_name} by {artist_names} is already in the playlist.")

                # If the song was only added to "Liked Songs"
                if not added_to_playlist:
                    show_overlay(f"Liked: {track_name}, {artist_names}", duration=3)

            else:
                print("No track is currently playing.")

        except spotipy.exceptions.SpotifyException as e:
            print(f"Spotify API error: {e}")

    else:
        print("Failed to retrieve or refresh token.")
