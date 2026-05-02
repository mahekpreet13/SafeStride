# Safestride

The **Safestride App** is a Flutter-based mobile application that improves safety for *Vulnerable Road Users (Safestrides)* such as blind and visually impaired pedestrians. It combines real-time navigation, open data, and smart alerts to help users move more safely through city environments.

## Overview

The app provides accessible navigation with live hazard awareness. It uses open data from accident maps and real-time location services to identify danger zones along a user’s route. When entering such areas, the app issues immediate visual and audio alerts.

The goal is to demonstrate how mobile technology and open data can make urban travel safer and more inclusive.

## Key Features

- **Personalized Onboarding:** Users select their impairment type and emergency contact.
- **Smart Navigation:** Map-based route guidance powered by OpenStreetMap and GraphHopper.
- **Danger Zone Detection:** Integration with Regensburg accident data to highlight high-risk areas.
- **Real-Time Alerts:** Notifies the user when entering or leaving a danger zone.
- **Emergency Contact:** Quick access to a saved contact for emergencies.
- **Accessible Interface:** Simple steps, large buttons, and clear feedback.

## Technical Summary

- Built with **Flutter** and **BLoC architecture** for state management.
- Uses **Geolocator** for GPS tracking and **Flutter Compass** for direction.
- Fetches routes from **GraphHopper API** and location data from **Nominatim**.
- Displays live maps with **Flutter Map** and overlays safety zones from local data (`Unfallatlas`).

## Why It Matters

This project is more than a navigation app — it’s a prototype for safer mobility. It shows how technology can assist people with visual impairments and contribute to smarter, more inclusive cities.


