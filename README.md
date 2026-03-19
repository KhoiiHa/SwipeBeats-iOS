# 🎧 SwipeBeats

SwipeBeats ist eine moderne iOS-App zur schnellen Musik-Discovery über kurze Audio-Previews.  
Die App kombiniert klassische Suche mit einem Swipe-basierten Flow, um neue Songs intuitiv zu entdecken, zu speichern und zu organisieren.

👉 Fokus: **schnelles Entdecken, direktes Vorhören und einfache Organisation von Musik**

---

## 📱 App Preview

<!-- Hier kommen deine Screenshots rein -->
<!-- Beispiel: -->
<!-- ![Swipe](./screens/swipe.png) -->

---

## 🚀 Core Features

### 🔍 Explore – Musik entdecken
- Freie Suche nach Künstlern, Songs oder Genres  
- Presets für schnellen Einstieg  
- Filter & Sortierung (z. B. nur Tracks mit Preview)  
- Suchverlauf für schnellen Zugriff  

### 🔄 Swipe Discovery
- Tinder-ähnlicher Flow zum Durchgehen von Tracks  
- Direktes Skippen oder Favorisieren  
- Schneller Zugriff auf Track-Details  

### ▶️ Globaler Audio-Player
- 30-Sekunden-Previews über die gesamte App hinweg  
- Globaler MiniPlayer mit konsistentem Playback-Kontext  
- Nahtloser Wechsel zwischen Screens (Explore, Swipe, Favoriten, Playlists)  

### ❤️ Favoriten
- Tracks liken / entliken  
- Persistente Speicherung über SwiftData  
- Schneller Zugriff auf gespeicherte Songs  

### 📂 Playlists
- Playlists erstellen, umbenennen und löschen  
- Tracks zu Playlists hinzufügen  
- Einzelne Tracks direkt aus Playlists abspielen  

---

## 🧰 Tech Stack

- **Swift & SwiftUI** – moderne UI-Entwicklung  
- **MVVM Architektur** – klare Trennung von UI und Logik  
- **SwiftData** – lokale Persistenz  
- **AVFoundation / AVPlayer** – Audio-Wiedergabe  
- **URLSession** – Networking  
- **iTunes Search API** – Datenquelle für Musik  

---

## 🏗 Architektur

Die App folgt einer MVVM-Struktur:

- **Views** → UI und User-Interaktion  
- **ViewModels** → State-Management und Use-Cases  
- **Services & Stores** → Persistenz und systemnahe Logik  

### Zentrale Komponenten

- `AppRootView` → Tab-Struktur, MiniPlayer, Toast-System  
- `AudioPlayerService` → globaler Audio-Flow  
- `ExploreViewModel` → Suche, Filter, History  
- `SwipeViewModel` → Swipe-Logik  
- `LikedTracksStore` → Favoritenverwaltung  
- `PlaylistStore` → Playlist-CRUD und Track-Snapshots  

---

## ✨ Technische Highlights

- 🎵 **Globaler Audio-Flow**  
  Konsistenter Playback-State über mehrere Screens hinweg inkl. MiniPlayer  

- 🔎 **Flexible Search-Logik**  
  Kombination aus Presets, manueller Suche und Artist-Navigation  

- ⚡ **Performanter Like-State**  
  Cache-basierte Verwaltung statt wiederholter Datenbankzugriffe  

- 📂 **Playlist-System mit Snapshots**  
  Tracks werden als Snapshot gespeichert → stabile Anzeige & Preview  

- 🔔 **Globales Toast-System**  
  Wiederverwendbares Feedback-System für Aktionen  

---

## ⚠️ Aktueller Scope (MVP)

SwipeBeats ist bewusst als leichtgewichtige Discovery-App umgesetzt:

- Audio basiert auf **30-Sekunden-Previews** (kein Full Streaming)  
- Playlists haben **kein vollständiges Queue-System**  
- „Playlist abspielen“ startet aktuell nur den ersten Track  
- Keine Cloud-Synchronisation oder Accounts  

---

## 🧠 Learnings

Während der Entwicklung lag der Fokus auf:

- Aufbau eines konsistenten globalen Audio-Systems  
- Strukturierung einer skalierbaren SwiftUI + MVVM Architektur  
- Performance-Optimierung bei Listen und Like-Status  
- sauberes UI/UX-Polishing für eine konsistente Nutzererfahrung  

---

## 🔮 Future Improvements

- Erweiterung des Playlist-Systems (Queue, Next Track)  
- Verbesserte Audio-Steuerung und Playback-Features  
- Optionaler Cloud-Sync für Favoriten & Playlists  
- Weitere Discovery-Mechaniken  

---

## 👨‍💻 Autor

Minh Khoi Ha  
Junior iOS Developer  
