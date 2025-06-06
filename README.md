# Bolonyay App

Bolonyay App is a mobile application designed to connect individuals seeking legal assistance (petitioners) with qualified legal professionals (advocates). The app aims to streamline the process of finding and engaging with legal help.

## Features

*   **User Authentication:** Secure sign-up and login for petitioners and advocates using Email/Password and Google Sign-In (via Firebase Authentication).
*   **Onboarding Process:** A guided onboarding flow for new users to collect necessary information based on their role (petitioner or advocate). This includes details like user type, basic personal information, contact details, and advocate-specific information such as bar registration number, areas of specialization, and years of experience.
*   **User Roles:** Distinct roles for Petitioners (users seeking legal help) and Advocates (legal professionals offering services).
*   **Dashboard:** A personalized dashboard for users to view their profile information and access app features.
*   **Profile Management:** Users can manage their profile information.
*   **Firebase Integration:** Leverages Firebase for backend services including authentication (Firebase Authentication) and data storage (Firestore).

## Tech Stack

*   **Language:** Swift
*   **UI Framework:** SwiftUI
*   **Backend Services:**
    *   Firebase Authentication (for user sign-up, login)
    *   Firebase Firestore (for data storage)
*   **Dependency Management:** Swift Package Manager (implied by project structure)
*   **IDE:** Xcode

## Project Structure

The Bolonyay App codebase is organized as follows:

*   **`Bolonyay App/`**: Main directory for the application code.
    *   **`Assets.xcassets/`**: Contains app icons, images, and other assets.
    *   **`Bolonyay_AppApp.swift`**: The main entry point of the application, responsible for initializing Firebase and setting up the initial view.
    *   **`GoogleService-Info.plist`**: Configuration file for Firebase services.
    *   **`Manager/`**: Contains manager classes responsible for handling specific functionalities.
        *   **`AuthenticationManager.swift`**: Manages user authentication processes, including sign-up, sign-in, sign-out, and user profile management with Firebase.
    *   **`Model/`**: Contains data models used throughout the application.
        *   **`SplashViewModel.swift`**: ViewModel associated with the splash screen.
        *   **`UserProfile.swift`** (within `AuthenticationManager.swift`): Defines the structure for user profile data.
    *   **`Views/`**: Contains all SwiftUI views for different screens and UI components.
        *   **`AppCoordinator.swift`**: Manages the overall application state and navigation flow between different views (e.g., Splash, Login, Onboarding, Dashboard).
        *   **`Authentication/`**: Views related to user authentication (e.g., `EmailAuthView.swift`, `LoginView.swift`).
        *   **`Onboarding/`**: Views and components for the user onboarding process (e.g., `OnboardingView.swift`, `UserTypeSelectionView.swift`, `BasicInfoView.swift`).
        *   **`DashboardView.swift`**: The main view displayed after a user logs in and completes onboarding.
        *   **`SplashScreen/`**: View for the splash screen displayed at app launch.
*   **`Bolonyay App.xcodeproj/`**: Xcode project file.
*   **`Bolonyay AppTests/`**: Unit tests for the application.
*   **`Bolonyay AppUITests/`**: UI tests for the application.

## Setup/Installation

To run the Bolonyay App project:

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    ```
2.  **Open the project in Xcode:**
    Navigate to the project directory and open `Bolonyay App.xcodeproj`.
3.  **Firebase Setup:**
    *   This project uses Firebase for backend services. You will need to set up your own Firebase project and add your `GoogleService-Info.plist` file to the `Bolonyay App/` directory.
    *   Ensure you have configured Firebase Authentication (Email/Password and Google Sign-In) and Firestore in your Firebase project console.
4.  **Dependencies:**
    *   The project uses Swift Package Manager for dependencies. Xcode should automatically resolve these. If you encounter issues, ensure you have a stable internet connection and that the package URLs are accessible.
5.  **Build and Run:**
    *   Select a simulator or a connected device in Xcode and click the "Run" button.

*(Further detailed setup instructions for specific SDKs or environment configurations can be added here if needed.)*

## How to Contribute

Contributions are welcome! If you'd like to contribute to the Bolonyay App, please follow these general steps:

1.  Fork the repository.
2.  Create a new branch for your feature or bug fix: `git checkout -b feature-name` or `bugfix-name`.
3.  Make your changes and commit them with clear and descriptive messages.
4.  Push your changes to your forked repository.
5.  Create a pull request to the main repository's `main` or `develop` branch (please specify which branch to target if applicable).

*(More detailed contribution guidelines, coding standards, or issue tracking information can be added here.)*

## License

This project is currently not licensed. *(You can replace this with your chosen license, e.g., MIT License, Apache 2.0 License. If you do, consider adding a `LICENSE` file to the repository as well.)*
