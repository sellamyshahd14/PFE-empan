# flutter_application_1

A new Flutter project.

## How to Run & Debug

### Prerequisites
1.  **Flutter SDK**: Ensure Flutter is installed and added to your PATH.
2.  **VS Code Extension**: Install the "Flutter" extension for VS Code.
3.  **Device**: 
    -   Physical Android/iOS device (Recommended for Microphone/Speech features).
    -   Emulator/Simulator (Microphone might not work reliably).

### Running the App
1.  Open the project in **VS Code**.
2.  Select a target device from the bottom-right corner (or press `Ctrl+Shift+P` -> `Flutter: Select Device`).
3.  Press **F5** or go to `Run -> Start Debugging`.

### Troubleshooting
-   **Microphone Permissions**: If the app crashes or fails to record, ensure you've granted microphone permissions on the device.
-   **Firebase**: The app attempts to initialize Firebase. If you haven't set up `firebase_options.dart` with your project keys, some features might fail, but the app should launch.

