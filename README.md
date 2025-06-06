# Bolonyay App
Bolonyay App is a mobile application designed to connect individuals seeking legal assistance (petitioners) with qualified legal professionals (advocates). The app aims to streamline the process of finding and engaging with legal help, providing a modern, accessible platform for legal interactions.

## Table of Contents

1.  [Features](#features)
2.  [Tech Stack](#tech-stack)
3.  [Project Structure](#project-structure)
4.  [Setup/Installation](#setupinstallation)
    1.  [Prerequisites](#prerequisites)
    2.  [Clone the Repository](#clone-the-repository)
    3.  [Firebase Configuration (Crucial Step)](#firebase-configuration-crucial-step)
    4.  [Open Project in Xcode](#open-project-in-xcode)
    5.  [Install Dependencies](#install-dependencies)
    6.  [Build and Run](#build-and-run)
    7.  [Troubleshooting](#troubleshooting)
5.  [How to Contribute](#how-to-contribute)
6.  [License](#license)

---

## Features

*   **User Authentication:**
    *   Secure sign-up and login capabilities for both petitioner and advocate users.
    *   Supports authentication via traditional Email/Password.
    *   Integrates Google Sign-In for a quick and easy authentication alternative.
    *   Utilizes Firebase Authentication for robust and secure user management.

*   **Comprehensive Onboarding Process:**
    *   A multi-step, guided onboarding experience tailored to the user type (Petitioner or Advocate).
    *   Collects essential user information, including:
        *   **User Type Selection:** Clear choice between Petitioner and Advocate roles.
        *   **Basic Information:** Full name, email address (auto-filled if available from Google Sign-In).
        *   **Contact Details:** Mobile number for communication.
        *   **Advocate-Specific Details:** For users registering as Advocates, the onboarding collects:
            *   Bar Registration Number.
            *   Areas of Legal Specialization.
            *   Years of Professional Experience.
            *   Location details: Enrolled State and District.
    *   Ensures users provide all necessary details before accessing the main application features.
[comment]: <> (Consider adding a screenshot or a small GIF of the onboarding flow, e.g., ![Onboarding Flow](docs/images/onboarding_flow.gif))

*   **Distinct User Roles & Permissions:**
    *   **Petitioners:** Users seeking legal assistance. The app will provide them tools to find advocates and manage their legal needs (details of petitioner-specific features can be expanded here as they are built).
    *   **Advocates:** Legal professionals offering their services. The app will allow them to showcase their expertise and connect with petitioners (details of advocate-specific features can be expanded here as they are built).

*   **Personalized User Dashboard:**
    *   Displays a summary of the user's profile information in an accessible and user-friendly interface.
    *   Serves as the main landing area after login and onboarding, providing access to further app functionalities.
    *   Information displayed includes name, email, mobile number, user type, and advocate-specific details if applicable.
[comment]: <> (Consider adding a screenshot of the Dashboard view, e.g., ![User Dashboard](docs/images/dashboard_screenshot.png))

*   **Profile Management:**
    *   Allows users to view and potentially update their profile information after onboarding (specific editable fields can be detailed further).

*   **Robust Firebase Backend Integration:**
    *   Leverages Firebase Authentication for managing all aspects of user sign-up, login, and session persistence.
    *   Uses Firebase Firestore as a scalable NoSQL database for storing user profiles and other application data.
    *   Ensures data persistence and synchronization across devices.

## Tech Stack

*   **Language:** Swift
*   **UI Framework:** SwiftUI
*   **Backend Services:**
    *   Firebase Authentication (for user sign-up, login)
    *   Firebase Firestore (for data storage)
*   **Dependency Management:** Swift Package Manager (implied by project structure)
*   **IDE:** Xcode

## Project Structure

The Bolonyay App codebase is organized to promote clarity and separation of concerns, primarily using SwiftUI's declarative approach.

*   **`Bolonyay App/`**: This is the root directory for all the application's source code and primary resources.
    *   **`Assets.xcassets/`**: Stores all visual assets for the app. This includes the app icon, images used within views (like `loginphoto`), and custom color sets (e.g., `AccentColor`).
    *   **`Bolonyay_AppApp.swift`**: The main entry point of the SwiftUI application. It conforms to the `App` protocol. Its primary responsibilities are:
        *   Initializing critical services, notably Firebase, using `FirebaseApp.configure()`.
        *   Defining the main application scene and launching the initial UI, which is handled by `AppCoordinatorView`.
    *   **`GoogleService-Info.plist`**: The crucial Firebase configuration file. It contains all the necessary keys and identifiers for the app to connect with the Firebase backend services. **Note:** This file is specific to your Firebase project and should not be committed if the repository is public without appropriate security measures.
    *   **`Manager/`**: This directory houses classes that manage specific business logic or services.
        *   **`AuthenticationManager.swift`**: A key class responsible for all aspects of user authentication. It interacts with Firebase Authentication to handle user sign-up (email & Google), sign-in, sign-out, and session management. It also manages loading and saving `UserProfile` data to Firestore.
    *   **`Model/`**: Contains the data structures (models) that represent the application's data.
        *   **`SplashViewModel.swift`**: A ViewModel likely used to manage the state or any logic associated with the `SplashView`.
        *   **`UserProfile.swift`** (defined within `AuthenticationManager.swift`): This struct models the user's profile information, including their ID, email, name, onboarding status, user type (Petitioner/Advocate), and other role-specific details. It is Codable for easy storage and retrieval from Firestore.
    *   **`Views/`**: This is the largest directory, containing all the SwiftUI views that make up the application's user interface.
        *   **`AppCoordinator.swift` / `AppCoordinatorView.swift`**: Implements a coordinator pattern to manage the application's overall navigation and state transitions (e.g., from Splash to Login, Login to Onboarding, Onboarding to Dashboard). It uses an `AppState` enum and `NotificationCenter` to react to navigation events.
        *   **`Authentication/`**: Contains views specifically for the authentication process:
            *   `LoginView.swift`: UI for user login.
            *   `EmailAuthView.swift`: UI for email-based sign-up/sign-in.
            *   `PrivacyPolicyView.swift` & `TermsConditionsView.swift`: Views to display legal information.
        *   **`Onboarding/`**: Holds all views and sub-components related to the user onboarding flow. This is a multi-step process guided by `OnboardingCoordinator`.
            *   `OnboardingView.swift`: The main container view for the onboarding steps.
            *   `OnboardingCoordinator.swift`: Manages the state and navigation within the onboarding process (e.g., current step, user type).
            *   Views for individual steps like `UserTypeSelectionView.swift`, `BasicInfoView.swift`, `AdvocateDetailsView.swift`, `LocationInfoView.swift`, and `CompletionView.swift`.
            *   `Components/`: Likely contains reusable UI elements specific to the onboarding flow.
        *   **`DashboardView.swift`**: The main screen presented to the user after successful login and completion of the onboarding process. It displays user information and will be the hub for further application features.
        *   **`SplashScreen/`**:
            *   `SplashView.swift`: The initial view shown when the app launches, possibly for branding or initial data loading.

*   **`Bolonyay App.xcodeproj/`**: The Xcode project file. This file manages all the project settings, configurations, targets, and file references. It's what you open in Xcode to work on the app.
*   **`Bolonyay AppTests/`**: Contains files for unit testing the application's logic (e.g., testing functions in `AuthenticationManager` or ViewModels).
    *   `Bolonyay_AppTests.swift`: An example unit test file.
*   **`Bolonyay AppUITests/`**: Contains files for UI testing the application. These tests interact with the app's UI elements to verify user flows and screen layouts.
    *   `Bolonyay_AppUITests.swift` & `Bolonyay_AppUITestsLaunchTests.swift`: Example UI test files.
*   **`Bolonyay-App-Info.plist`**: An older style Info.plist, likely for project-level settings if not fully migrated to build settings or the modern Info tab in Xcode. (It's good practice to manage most settings via the target's Info tab or build settings directly).

## Setup/Installation

To get the Bolonyay App up and running on your local machine for development or testing, follow these steps:

1.  **Prerequisites:**
    *   Ensure you have the latest version of Xcode installed from the Mac App Store.
    *   A stable internet connection is required for cloning and fetching dependencies.
    *   You will need an Apple Developer account if you plan to run the app on a physical iOS device.

2.  **Clone the Repository:**
    Open your terminal and clone the project repository using Git:
    ```bash
    git clone <your-repository-url-here> # Replace <your-repository-url-here> with the actual URL
    cd Bolonyay-App # Or your project's root folder name
    ```

3.  **Firebase Configuration (Crucial Step):**
    This application relies heavily on Firebase for its backend services (Authentication and Firestore).
    *   **Create a Firebase Project:** If you haven't already, go to the [Firebase Console](https://console.firebase.google.com/) and create a new Firebase project.
    *   **Register Your App:**
        *   Within your Firebase project, add a new iOS app.
        *   Enter the Bundle Identifier for this project. You can find this in Xcode: select the `Bolonyay App` target, then go to the "Signing & Capabilities" tab. The Bundle ID is usually in the format `com.yourdomain.BolonyayApp`.
        *   Download the `GoogleService-Info.plist` file provided by Firebase.
    *   **Add `GoogleService-Info.plist` to Xcode:**
        *   Drag and drop the downloaded `GoogleService-Info.plist` file into the `Bolonyay App/` folder in your Xcode project navigator.
        *   When prompted, ensure "Copy items if needed" is checked and that the file is added to the `Bolonyay App` target.
    *   **Enable Authentication Methods:**
        *   In the Firebase Console, navigate to "Authentication" -> "Sign-in method."
        *   Enable "Email/Password" and "Google" as sign-in providers. For Google Sign-In, you might need to provide your app's SHA-1 fingerprint (Xcode can generate this, or Firebase might guide you).
    *   **Set up Firestore:**
        *   In the Firebase Console, navigate to "Firestore Database."
        *   Create a database. Start in "test mode" for initial development (which allows open access) or configure security rules for production. **Remember to secure your rules before deploying a live app.** The default rules often allow read/write if `auth != null`.
        *   The app expects a `users` collection where user profiles are stored.

4.  **Open Project in Xcode:**
    Navigate to the cloned project directory in Finder and double-click the `Bolonyay App.xcodeproj` file to open it in Xcode.

5.  **Install Dependencies:**
    *   The project uses Swift Package Manager (SPM) for managing dependencies (like Firebase SDKs).
    *   Xcode should automatically attempt to resolve and fetch these packages when you open the project. You can monitor this progress in the status bar at the top of Xcode.
    *   If it doesn't happen automatically, or if you encounter issues, go to "File" -> "Packages" -> "Resolve Package Versions."

6.  **Build and Run:**
    *   Select an iOS Simulator (e.g., iPhone 14 Pro) or a connected physical iOS device from the scheme menu at the top of Xcode.
    *   Press the "Run" button (the play icon) or use the shortcut `Cmd+R`.
    *   The app should build and launch on the selected simulator/device.

7.  **Troubleshooting:**
    *   **Missing `GoogleService-Info.plist`:** The app will likely crash or Firebase services will fail if this file is missing or improperly configured.
    *   **Dependency Resolution Issues:** Ensure your internet connection is stable. Sometimes, cleaning the build folder (`Cmd+Shift+K`) and restarting Xcode can help.
    *   **Signing Issues (for physical devices):** You may need to select your development team under the "Signing & Capabilities" tab for the `Bolonyay App` target.

This detailed setup should guide new developers in getting the project operational.

## How to Contribute

Contributions are welcome! If you'd like to contribute to the Bolonyay App, please follow these general steps:

1.  Fork the repository.
2.  Create a new branch for your feature or bug fix: `git checkout -b feature-name` or `bugfix-name`.
3.  Make your changes and commit them with clear and descriptive messages.
4.  Push your changes to your forked repository.
5.  Create a pull request to the main repository's `main` or `develop` branch (please specify which branch to target if applicable).


This project is currently not licensed. *(You can replace this with your chosen license, e.g., MIT License, Apache 2.0 License. If you do, consider adding a `LICENSE` file to the repository as well.)*
