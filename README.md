# Bolonyay App
Bolonyay App is a mobile application designed to bridge the gap between individuals seeking legal assistance (petitioners) and qualified legal professionals (advocates). It aims to simplify and modernize the process of finding, engaging, and managing legal help by providing an accessible, feature-rich platform for both user groups. The app streamlines case initiation, communication, and document management, making legal processes more transparent and efficient.

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
    *   Ensures users provide all necessary details before accessing the main application features. `[GIF of Onboarding Flow]`

*   **Distinct User Roles & Permissions:**
    *   **Petitioners:** Users seeking legal assistance. They can initiate cases, track their progress, interact with their chosen advocates, and manage relevant documents or information.
    *   **Advocates:** Legal professionals offering their services. They can manage their professional profiles, list their areas of specialization and experience, view case requests from petitioners, and manage accepted cases.

*   **Personalized User Dashboard:**
    *   Displays a summary of the user's profile information in an accessible and user-friendly interface.
    *   Serves as the main landing area after login and onboarding, providing access to further app functionalities.
    *   Information displayed includes name, email, mobile number, user type, and advocate-specific details if applicable. `[Screenshot of User Dashboard]`

*   **Detailed Case Management:**
    *   Allows petitioners to initiate and submit case details through a guided process.
    *   Provides a system for tracking the status and progress of submitted cases (e.g., filed, under review, pending, completed).
    *   Potentially facilitates communication or document sharing related to specific cases (general capability).
    *   Leverages `CaseRecord` structures (as seen in `FirebaseManager`) for storing comprehensive case information. `[Screenshot of Case Tracking Interface]`

*   **PDF Report Generation & Management:**
    *   Enables users (likely petitioners, or advocates for their cases) to generate PDF reports related to their cases.
    *   Offers local storage and management of these generated reports directly within the app.
    *   Includes features like viewing, sharing, and deleting reports, managed by the `ReportsManager`. `[Screenshot of Reports List or PDF Preview]`

*   **Voice-Assisted Input:**
    *   Integrates voice recognition capabilities to allow users to fill in forms or provide information using speech-to-text.
    *   Enhances accessibility and ease of use, particularly for lengthy text inputs during case creation or profile setup.
    *   Managed by components like `SimpleVoiceAutoFillManager`. `[Visual cue of voice input in action]`

*   **Multi-Language Support (Localization):**
    *   Designed to support multiple languages to cater to a diverse user base.
    *   Allows users to experience the app in their preferred language, enhancing usability and accessibility.
    *   Managed by the `LocalizationManager`.

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
*   **Native Frameworks:**
    *   PDFKit (for PDF generation and viewing)
    *   Speech (for voice-to-text functionality)
*   **Dependency Management:** Swift Package Manager (SPM)
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
        *   **`AuthenticationManager.swift`**: A key class responsible for all aspects of user authentication. It interacts with Firebase Authentication to handle user sign-up (email & Google), sign-in, sign-out, and session management. It also manages loading and saving user profile data (like `UserProfile` or `BoloNyayUser`) to Firestore.
        *   **`FirebaseManager.swift`**: Manages core interactions with Firebase services, particularly Firestore database operations for user profiles (e.g., `BoloNyayUser`), case records (`CaseRecord`), conversation sessions, and overall data persistence beyond just authentication.
        *   **`ReportsManager.swift`**: Responsible for managing PDF reports, including their creation (often using `PDFGenerationManager`), local storage, retrieval, deletion, and metadata management.
        *   **`PDFGenerationManager.swift`**: Focuses on the technical generation of PDF documents from application data, converting structured information into PDF format.
        *   **`LocalizationManager.swift`**: Handles language settings and provides localized strings throughout the application, enabling multi-language support by loading appropriate resources based on user preferences or device settings.
        *   **`SimpleVoiceAutoFillManager.swift`**: Manages the voice-to-text input functionality, interacting with speech recognition frameworks to enable users to fill text fields using voice commands.
    *   **`Model/`**: Contains the data structures (models) that represent the application's data.
        *   **`SplashViewModel.swift`**: A ViewModel likely used to manage the state or any logic associated with the `SplashView`.
        *   **`UserProfile.swift` / `BoloNyayUser.swift`**: These structs model the user's profile information (e.g., ID, email, name, user type, onboarding status, role-specific details like bar registration or case preferences). They are Codable for easy storage and retrieval from Firestore, primarily managed by `AuthenticationManager` and `FirebaseManager`.
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

To ensure your contributions align well with the project's goals, especially for UI/UX changes or new feature development, it's recommended to first understand the distinct workflows and needs of the two main user roles: Petitioners (individuals seeking legal help) and Advocates (legal professionals offering services). Familiarizing yourself with the existing features for each role will provide valuable context.

1.  Fork the repository.
2.  Create a new branch for your feature or bug fix: `git checkout -b feature-name` or `bugfix-name`.
3.  Make your changes and commit them with clear and descriptive messages.
4.  Push your changes to your forked repository.
5.  Create a pull request to the main repository's `main` or `develop` branch (please specify which branch to target if applicable).
