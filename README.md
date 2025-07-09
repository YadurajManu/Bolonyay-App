# BoloNyay

## Table of Contents

*   [Overview](#overview)
*   [Features](#features)
*   [Technology Stack](#technology-stack)
*   [Project Structure](#project-structure)
*   [Setup and Installation](#setup-and-installation)
    *   [Prerequisites](#prerequisites)
    *   [Clone the Repository](#clone-the-repository)
    *   [Firebase Configuration (Crucial Step)](#firebase-configuration-crucial-step)
    *   [Open Project in Xcode](#open-project-in-xcode)
    *   [Install Dependencies](#install-dependencies)
    *   [Build and Run](#build-and-run)
    *   [Troubleshooting](#troubleshooting)
*   [How to Contribute](#how-to-contribute)
*   [License](#license)
*   [Contact](#contact)

## Overview

Bolonyay App is a mobile application designed to bridge the gap between individuals seeking legal assistance (petitioners) and qualified legal professionals (advocates). It aims to simplify and modernize the process of finding, engaging, and managing legal help by providing an accessible, feature-rich platform for both user groups. The app streamlines case initiation, communication, and document management, making legal processes more transparent and efficient.

*This project is a highly confidential and professional undertaking for the Indian government.*

## Features

*   **User Authentication:**
    *   Secure sign-up and login capabilities for both petitioner and advocate users.
    *   Supports authentication via traditional Email/Password.
    *   Integrates Google Sign-In for a quick and easy authentication alternative.
    *   Utilizes Firebase Authentication for robust and secure user management.
*   **Comprehensive Onboarding Process:**
    *   A multi-step, guided onboarding experience tailored to the user type (Petitioner or Advocate).
    *   Collects essential user information, including:
        *   User Type Selection: Clear choice between Petitioner and Advocate roles.
        *   Basic Information: Full name, email address (auto-filled if available from Google Sign-In).
        *   Contact Details: Mobile number for communication.
        *   Advocate-Specific Details: For users registering as Advocates, the onboarding collects:
            *   Bar Registration Number.
            *   Areas of Legal Specialization.
            *   Years of Professional Experience.
            *   Location details: Enrolled State and District.
    *   Ensures users provide all necessary details before accessing the main application features.
*   **Distinct User Roles & Permissions:**
    *   Petitioners: Users seeking legal assistance. They can initiate cases, track their progress, interact with their chosen advocates, and manage relevant documents or information.
    *   Advocates: Legal professionals offering their services. They can manage their professional profiles, list their areas of specialization and experience, view case requests from petitioners, and manage accepted cases.
*   **Personalized User Dashboard:**
    *   Displays a summary of the user's profile information in an accessible and user-friendly interface.
    *   Serves as the main landing area after login and onboarding, providing access to further app functionalities.
    *   Information displayed includes name, email, mobile number, user type, and advocate-specific details if applicable.
*   **Detailed Case Management:**
    *   Allows petitioners to initiate and submit case details through a guided process.
    *   Provides a system for tracking the status and progress of submitted cases (e.g., filed, under review, pending, completed).
    *   Potentially facilitates communication or document sharing related to specific cases.
    *   Leverages `CaseRecord` structures for storing comprehensive case information.
*   **PDF Report Generation & Management:**
    *   Enables users to generate PDF reports related to their cases.
    *   Offers local storage and management of these generated reports directly within the app.
    *   Includes features like viewing, sharing, and deleting reports, managed by `ReportsManager`.
*   **Voice-Assisted Input:**
    *   Integrates voice recognition capabilities to allow users to fill in forms or provide information using speech-to-text.
    *   Enhances accessibility and ease of use, particularly for lengthy text inputs.
    *   Managed by `SimpleVoiceAutoFillManager`.
*   **Multi-Language Support (Localization):**
    *   Designed to support multiple languages to cater to a diverse user base.
    *   Managed by `LocalizationManager`.
*   **Profile Management:**
    *   Allows users to view and potentially update their profile information after onboarding.
*   **Robust Firebase Backend Integration:**
    *   Leverages Firebase Authentication for user sign-up, login, and session persistence.
    *   Uses Firebase Firestore for storing user profiles and other application data.

## Technology Stack

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
    *   **`Assets.xcassets/`**: Stores all visual assets for the app (app icon, images, custom color sets).
    *   **`Bolonyay_AppApp.swift`**: The main entry point of the SwiftUI application. Initializes Firebase and launches the initial UI (`AppCoordinatorView`).
    *   **`GoogleService-Info.plist`**: Firebase configuration file. *Note: This file is specific to your Firebase project and should not be committed if the repository is public without appropriate security measures.*
    *   **`Manager/`**: Houses classes that manage specific business logic or services.
        *   `AuthenticationManager.swift`: Handles user authentication (sign-up, sign-in, sign-out, session management) via Firebase Authentication and Firestore profile data.
        *   `FirebaseManager.swift`: Manages core interactions with Firebase services, especially Firestore database operations for user profiles, case records, etc.
        *   `ReportsManager.swift`: Manages PDF reports (creation, storage, retrieval, deletion).
        *   `PDFGenerationManager.swift`: Handles the technical generation of PDF documents.
        *   `LocalizationManager.swift`: Manages language settings and localized strings.
        *   `SimpleVoiceAutoFillManager.swift`: Manages voice-to-text input functionality.
    *   **`Model/`**: Contains data structures (models).
        *   `SplashViewModel.swift`: ViewModel for the splash screen.
        *   `UserProfile.swift` / `BoloNyayUser.swift`: Models for user profile information, Codable for Firestore.
    *   **`Views/`**: Contains all SwiftUI views.
        *   `AppCoordinator.swift` / `AppCoordinatorView.swift`: Manages navigation and state transitions.
        *   `Authentication/`: Views for the authentication process (login, email auth, privacy policy, terms).
        *   `Onboarding/`: Views for the multi-step user onboarding flow.
        *   `DashboardView.swift`: Main screen after login/onboarding.
        *   `SplashScreen/`: Initial launch screen.
    *   **`Bolonyay App.xcodeproj/`**: The Xcode project file, managing project settings and file references.

## Setup and Installation

### Prerequisites

*   Xcode installed (latest version recommended).
*   CocoaPods (if any Pods are used, though SPM is listed as the primary).
*   A Firebase project set up with Authentication and Firestore enabled.
*   Google Sign-In enabled in your Firebase project if you intend to use that feature.

### Clone the Repository

```bash
git clone <repository-url>
cd BolonyayAppIOS
```

### Firebase Configuration (Crucial Step)

1.  **Download `GoogleService-Info.plist`**:
    *   Go to your Firebase project console.
    *   Select your iOS app (or add one if it doesn't exist).
    *   Download the `GoogleService-Info.plist` file.
2.  **Add to Xcode Project**:
    *   Open the `Bolonyay App.xcodeproj` file in Xcode.
    *   Drag the downloaded `GoogleService-Info.plist` file into the `Bolonyay App/` group in the Xcode project navigator.
    *   Ensure it's added to the main app target when prompted. **Do not rename this file.**

### Open Project in Xcode

Open `Bolonyay App.xcodeproj` in Xcode.

### Install Dependencies

The project uses Swift Package Manager (SPM). Dependencies should resolve automatically when you open the project in Xcode. If not:

1.  In Xcode, go to `File` > `Packages` > `Resolve Package Versions`.
2.  If there are issues, ensure your internet connection is stable and try `File` > `Packages` > `Reset Package Caches` then resolve again.

*(If CocoaPods are used for any specific dependency not managed by SPM, you would run `pod install` in the project's root directory from the terminal.)*

### Build and Run

1.  Select a target simulator or a connected iOS device in Xcode.
2.  Click the "Play" button (or `Cmd+R`) to build and run the application.

### Troubleshooting

*   **Firebase Connection Issues**:
    *   Double-check that `GoogleService-Info.plist` is correctly placed and named.
    *   Ensure your Firebase project's Bundle ID matches the one in your Xcode project.
    *   Check internet connectivity.
*   **Dependency Issues (SPM)**:
    *   Try cleaning the build folder (`Cmd+Shift+K`).
    *   Reset package caches as mentioned above.
*   **Code Signing Issues (for running on a device)**:
    *   Ensure you have a valid Apple Developer account set up in Xcode and the correct team selected in "Signing & Capabilities".

## How to Contribute

Contributions to this project are highly restricted due to its confidential nature. Please contact the project administrator (Yaduraj Singh at yadurajsingham@gmail.com) for any inquiries or if you are authorized to contribute.

If you are authorized, please follow these general guidelines:

1.  **Fork the repository** (if applicable, for external contributors with permission).
2.  **Create a new branch** for your feature or bug fix: `git checkout -b feature/your-feature-name` or `bugfix/issue-tracker-id`.
3.  **Commit your changes** with clear, descriptive commit messages.
4.  **Push your branch** to the remote repository.
5.  **Open a Pull Request** against the main development branch, detailing the changes you've made.
6.  Ensure your code adheres to any specified coding standards or guidelines.
7.  Ensure all tests pass (if tests are implemented).

## License

This project is proprietary and confidential. All rights reserved.

Copyright (c) 2023 Ayush Singh

## Contact

For any questions or support, please contact Yaduraj Singh at yadurajsingham@gmail.com
---

**Note:** This project is of utmost importance and requires strict adherence to security and confidentiality protocols. All information related to this project must be handled with the highest level of discretion.
