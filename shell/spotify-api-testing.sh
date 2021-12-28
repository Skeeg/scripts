curl -X "GET" "https://api.spotify.com/v1/me/playlists?limit=1&offset=0" -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $spotifyToken"


PAGINGSIZE=50
PLLAST=$(curl -X "GET" "https://api.spotify.com/v1/me/playlists?limit=1&offset=0" -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $spotifyToken" -s | jq .total)
SEQLAST=$(($PLLAST/$PAGINGSIZE))
for SEQUENCE in $(seq 0 $SEQLAST)
do
  STARTOFFSET=$(($SEQUENCE*$PAGINGSIZE))
  # echo $STARTOFFSET
  curl -X "GET" "https://api.spotify.com/v1/me/playlists?limit=50&offset=$STARTOFFSET" -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $spotifyToken"
done > "$HOME/Downloads/ryanpeay-spotify-playlists.json"

#for userID in "ryanpeay Spotify Piano"
# for userID in "Piano"
# do
#   while IFS= read -r playlistID
#   do
#     curl -X "GET" "https://api.spotify.com/v1/playlists/$playlistID/tracks" -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $spotifyToken"
#   done < <(cat $HOME/Downloads/ryanpeay-spotify-playlists.json | jq -c '.items[] | {name, description, public, owner, id}' | grep "\"display_name\":\"$userID" | jq -r .id)
# done >> "$HOME/Downloads/ryanpeay-spotify-playlist-tracks.json"



# for userID in "ryanpeay Spotify"
# do
#   cat $HOME/Downloads/ryanpeay-spotify-playlists.json | jq -c '.items[] | {name, description, public, owner, id}' | grep "\"display_name\":\"$userID"
# done



for userID in "ryanpeay Spotify Piano"
do
  while IFS= read -r playlistID
  do
    curl -X "GET" "https://api.spotify.com/v1/playlists/$playlistID/tracks" -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $spotifyToken" -s
  done < <(cat $HOME/Downloads/ryanpeay-spotify-playlists.json | jq -c '.items[] | {name, description, public, owner, id}' | grep "\"display_name\":\"$userID" | jq -r .id)
done > "$HOME/Downloads/ryanpeay-spotify-playlist-tracks.json"



#Playlists:
curl -X "GET" "https://api.spotify.com/v1/me/playlists?limit=50&offset=$STARTOFFSET" -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $spotifyToken"

#Playlist Contents:
curl -X "GET" "https://api.spotify.com/v1/playlists/$playlistID/tracks" -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $spotifyToken" -s

#Loved Tracks
curl -X "GET" "https://api.spotify.com/v1/me/tracks" -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Bearer $spotifyToken"