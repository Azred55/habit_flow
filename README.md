# HabitFlow — Projektbeschreibung

## Was ist HabitFlow?

- Mobile App zum Aufbauen und Verfolgen täglicher Gewohnheiten mit Zitaten und Sync

---
## Features

### Gewohnheiten verwalten
- Eigene Habits erstellen, bearbeiten, löschen

### Tägliches Abhaken
- Hauptscreen zeigt alle Habits für heute
- Ein Tap markiert Habit als erledigt
- Fortschrittsanzeige (z.B. "4 von 6 erledigt")

### Streaks
- Zählt aufeinanderfolgende Tage mit erledigten Habits
- Prominente Anzeige 
- Streak bricht bei verpasstem Tag ab

### Motivationszitate
- Inspirierendes Zitat beim App-Start
- Zitate von externer API (DummyJSON)
- Neues Zitat per Pull-to-Refresh

### Einstellungen
- Theme wählen (Hell / Dunkel / System)
- Benachrichtigungen ein/aus
- Erinnerungszeit festlegen

### Offline-First mit Cloud-Sync
- App funktioniert komplett offline
- Lokale Speicherung mit Hive und SharedPreferences
- Automatischer Sync mit Supabase

---

## Verlauf des Projekts:

### Montag: 
- Vorstellung Projekt
- Projektaufgabe Persistente Liste (Abgabe Mittwoch 9:00 Uhr)
### Dienstag:
- Aufbau Architektur/UML/Setup
- Setup Supabase
### Mittwoch: 
- Review Projektaufgabe + Umbau 
- Projektaufgabe Anbindung Backend (Abgabe Freitag 9:00 Uhr)
### Donnerstag: 
- Anbindung DummyJSON (Zitate) + Settings
- Wissenscheck
### Freitag:
- Review Anbindung Backend
- Einbauen Streaks
