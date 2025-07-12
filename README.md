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
<img width="1521" alt="Screenshot 2025-07-03 at 6 58 48 PM" src="https://github.com/user-attachments/assets/262d0fb9-a011-46ed-8d9e-3e0e9bee2e49" />


