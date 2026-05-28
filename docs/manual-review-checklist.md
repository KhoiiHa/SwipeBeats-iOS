# SwipeBeats Manual Review Checklist

Use this checklist before merging or presenting the portfolio version.

## Build

- [ ] Open the project in Xcode.
- [ ] Select the `SwipeBeats` scheme.
- [ ] Build the app for an iPhone simulator.
- [ ] Confirm the app launches without a crash.

## Explore

- [ ] Preset search loads results.
- [ ] Manual search loads results.
- [ ] Empty search returns to the idle state.
- [ ] Filter "only with preview" hides tracks without previews.
- [ ] Sorting by track title works.
- [ ] Recent searches can be reused.
- [ ] Error and empty states look consistent and readable.

## Swipe

- [ ] Initial preset loads tracks.
- [ ] Genre picker reloads the Swipe deck.
- [ ] Skip advances to the next track.
- [ ] Like saves the track to favorites.
- [ ] Detail button opens the selected track.
- [ ] Empty state after the last track offers reload.
- [ ] Error state offers retry.

## Playback

- [ ] Track detail preview starts and pauses.
- [ ] MiniPlayer appears while playback is active.
- [ ] Stop button clears the MiniPlayer.
- [ ] Next button is disabled outside playlist queues.
- [ ] Next button advances inside playlist queues.

## Favorites

- [ ] Liked tracks appear in Favorites.
- [ ] Favorite preview can start from the list.
- [ ] Removing a favorite updates the list.
- [ ] Empty Favorites state is understandable.

## Playlists

- [ ] Playlist creation works.
- [ ] Playlist renaming works.
- [ ] Playlist deletion works.
- [ ] Tracks can be added from Track Detail.
- [ ] Playlist detail shows track count/playable count.
- [ ] Playlist play starts a queue.
- [ ] Starting playback from a playlist row begins at that track.
- [ ] Tracks without previews are visibly disabled.
- [ ] Empty playlist state explains what to do next.

## Screenshots

- [ ] `screens/swipe.png` reflects the current Swipe UI.
- [ ] `screens/explore.png` reflects the current Explore UI.
- [ ] `screens/detail.png` reflects the current Track Detail UI.
- [ ] `screens/favorites.png` reflects the current Favorites UI.
- [ ] `screens/playlists.png` reflects the current Playlist overview UI.
- [ ] `screens/playlist-detail.png` reflects the current Playlist detail UI.

## Portfolio Readiness

- [ ] README screenshots render on GitHub.
- [ ] README feature list matches the current app.
- [ ] README case study is understandable without extra context.
- [ ] Known MVP limits are described clearly.
