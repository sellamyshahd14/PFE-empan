# Project Context: Medical Cognitive Evaluation App

## 1. Purpose
A mobile medical application designed for doctors in Tunisia (Habib Bourguiba Hospital, Sfax) to evaluate patients with cognitive and behavioral symptoms. The goal is to differentiate between Alzheimer’s Disease, Depression, and other cognitive disorders.

## 2. Tech Stack
- **Framework:** Flutter (Dart)
- **Backend:** Firebase (Auth, Firestore)
- **Key Packages:** `speech_to_text`, `flutter_tts`, `cloud_firestore`, `firebase_auth`, `google_fonts`.
- **Localization:** Bilingual (Arabic 'ar' as default, French 'fr').

## 3. Core Features & Tests
The app integrates 8 standardized clinical tests:
1.  **Empan (Direct & Inverse):** Memory span via voice/audio.
2.  **TMT (A, B, C):** Executive function via touch/drawing (1-25, 1-A-2-B, and 1-A...8-H).
3.  **HADS:** Anxiety/Depression questionnaire.
4.  **DO-30:** Image naming (30 items) with voice recognition.
5.  **DSM-48:** Visual recognition memory (Encodage + 3 Sets).

## 4. Data Architecture
- **Doctors:** Stored in `doctors` collection (UID, DoctorID, Email).
- **Patients:** Stored in `patients` collection. Linked to a doctor via `createdByDoctorId`.
- **Results:** Stored in `results` collection. 
    - Fields: `patientId`, `testType`, `duration`, `errors`, `score`, `timestamp`.
    - Special: HADS uses `scoreA` (Anxiety) and `scoreD` (Depression).

## 5. UI/UX Standards
- **Primary Color:** Teal (`Colors.teal`).
- **Font:** Cairo (for Arabic/French readability).
- **Navigation:** Doctor Dashboard -> Patient Details -> Test Selection.