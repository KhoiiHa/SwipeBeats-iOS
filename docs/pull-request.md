# Pull Request: Playlist Playback & MVP Polish

## Ziel

Dieser Branch bringt SwipeBeats näher an einen vorzeigbaren MVP-Stand. Der Fokus liegt auf Playlist-Playback, stabileren Kernflows, klareren UI-States und einer besseren Portfolio-Dokumentation.

## Wichtige Änderungen

- Playlist-Playback erzeugt jetzt eine einfache Queue aus spielbaren Tracks.
- Der MiniPlayer kann innerhalb einer Playlist-Queue zum nächsten Track springen.
- Playlist-Detail kann Playback ab einem ausgewählten Track starten.
- Favoriten können direkt aus der Liste als Preview abgespielt werden.
- Swipe-, Explore- und Playlist-States wurden für Empty/Error-Situationen geglättet.
- Ein leerer DeepLink-Service wurde entfernt.
- README wurde zur Portfolio-/Case-Study erweitert.

## Tests

Abgesichert sind unter anderem:

- Explore filtert Tracks ohne Preview.
- Explore sortiert Tracks alphabetisch.
- Explore zeigt spezifische Netzwerkfehler.
- Explore behält Error-State bei Filteränderungen.
- Swipe springt beim Skip zum nächsten Track.
- Swipe zeigt nach dem letzten Track einen Empty-State.
- Swipe stoppt aktive Wiedergabe beim Skip.
- Audio-Queue setzt `nowPlayingTrack` und `hasNextTrack` korrekt.
- Audio-Queue kann ab einem ausgewählten Track starten.

Verifikation:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild build-for-testing \
  -project SwipeBeats/SwipeBeats.xcodeproj \
  -scheme SwipeBeats \
  -destination 'generic/platform=iOS Simulator'
```

## Edge Cases

- Tracks ohne Preview werden in Playlist-Playback nicht abgespielt.
- Playlists mit nur nicht spielbaren Tracks zeigen einen deaktivierten Play-State.
- Der vollständige Simulator-Testlauf kann lokal beim Start des Simulators hängen; `build-for-testing` kompiliert die Test-Targets erfolgreich.

## Manuelle Review

Vor Merge oder Portfolio-Veröffentlichung sollte `docs/manual-review-checklist.md` einmal im Simulator durchgeklickt werden.
