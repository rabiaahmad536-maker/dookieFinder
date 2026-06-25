# DookiFinder 📍📱

A location-based mobile application designed to optimize and streamline campus navigation by map-routing users to essential facilities across the University of Guelph. Built using a user-centric design philosophy, the application integrates dynamic filtering, community-driven data systems, and real-time navigation shortcuts.

---

## Key Features & Architectural Capabilities

*   **Map-Based Interface:** Visualizes critical facilities across campus using intuitive, identifiable geographical markers.
*   **Combinable Query Filters:** Allows users to selectively toggle and layer map views based on multiple specific washroom attributes.
*   **Student-Led Rating & Review System:** Built a community data loop enabling users to view local facility ratings, read qualitative reviews, and submit authenticated feedback.
*   **The "Emergency Button" Shortcut:** A novel, high-utility feature that instantly computes and displays an optimized path to the absolute nearest facility from the user's current coordinates.

---

## Technical Stack & Tools

*   **Mobile Development:** Mobile Application Framework, UI State Management
*   **Frontend & Application Framework:** Flutter, Dart
*   **Geospatial Tracking:** Map APIs, Coordinate Routing, Location Services

---

## Installation & Local Setup

### 1. Clone the Repository

```bash
git clone https://github.com/rabiaahmad536-maker/dookieFinder.git
cd dookieFinder
```

### 2. Install Dependencies

Run the following command to install all required packages:

```bash
flutter pub get
```

### 3. Configure Google Maps API Key

Obtain a Google Maps API key from the Google Cloud Console.

Then, add the following metadata tag to:

`android/app/src/main/AndroidManifest.xml`

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE" />
```

### 4. Build and Run the Application

Open Android Studio and either:

- Launch an Android Virtual Device (AVD), or
- Connect a physical Android device.

Then run:

```bash
flutter run
```
