# AroggyaPath

**AroggyaPath** is a comprehensive healthcare application built with Flutter, designed to bridge the gap between patients and doctors. It facilitates seamless appointment booking, real-time communication, and efficient healthcare management.

## 🚀 Key Features

*   **Role-Based Access**: Dedicated interfaces for **Patients** and **Doctors**.
*   **Appointment Management**: Easy booking, rescheduling, and cancellation of appointments.
*   **Real-Time Chat**: Integrated chat functionality for instant communication between patients and doctors.
*   **Video Consultations**: High-quality video calls powered by **Jitsi Meet**.
*   **Interactive Maps**: **OpenStreetMap** integration to find nearby doctors and clinics.
*   **Notifications**: Push notifications via **Firebase Cloud Messaging** to keep users updated.
*   **Secure Authentication**: Robust user authentication managed by **Supabase**.
*   **Dependents**: Manage health profiles for family members.

## 🛠 Tech Stack

*   **Framework**: [Flutter](https://flutter.dev/) (Dart)
*   **Backend & Auth**: [Supabase](https://supabase.com/)
*   **Notifications**: [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
*   **State Management**: 
    *   [Riverpod](https://riverpod.dev/) (Primary)
    *   [Provider](https://pub.dev/packages/provider) (Legacy/Hybrid)
*   **Maps**: [flutter_map](https://pub.dev/packages/flutter_map) (OpenStreetMap)
*   **Video Calls**: [Jitsi Meet](https://jitsi.org/jitsi-meet/)
*   **Local Storage**: `shared_preferences`, `flutter_secure_storage`

## 🏁 Getting Started

Follow these steps to set up the project locally.

### Prerequisites

*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (Version `^3.10.4`)
*   Dart SDK
*   Android Studio / Xcode (for mobile emulation)

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/aroggyapath.git
    cd aroggyapath
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Configuration:**
    *   **Supabase**: The project uses Supabase for backend services. Configuration is located in `lib/utils/supabase_config.dart`. Ensure you have the correct URL and Anon Key.
    *   **Firebase**: Firebase is used for notifications. The `firebase_options.dart` file contains the configuration for different platforms.
    *   **Maps**: Ensure location permissions are set up in `AndroidManifest.xml` and `Info.plist`.

4.  **Run the app:**
    ```bash
    flutter run
    ```

## 📂 Project Structure

```
lib/
├── config/             # App-wide configuration
├── l10n/              # Localization files
├── models/            # Data models
├── providers/         # State management (Riverpod/Provider)
├── screens/           # UI Screens
│   ├── auth/          # Authentication screens
│   ├── doctor/        # Doctor-specific screens
│   ├── patient/       # Patient-specific screens
│   └── ...
├── services/          # API, Socket, and other services
├── utils/             # Helper functions and constants
└── widgets/           # Reusable UI components
```

## 🤝 Contributing

Contributions are welcome! Please fork the repository and submit a pull request for any enhancements or bug fixes.

---
*Built with ❤️ for better healthcare.*
