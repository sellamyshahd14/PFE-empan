# Gemini Flash Agent Prompt — Flutter Test App Modifications



## CONTEXT

You are a Flutter/Dart expert tasked with modifying two test screens in a clinical neuropsychology mobile application. The app administers cognitive tests to patients. You will receive two Dart files as input:

1. **`do30_test.dart`** — The DO-30 oral image naming test (30 images, patient must name each image aloud or in writing)
2. **`dsm48_encodage.dart`** — The DSM-48 encoding test (48 images, patient must describe each image aloud)

Read both files carefully before making any changes. Then apply ALL of the modifications described below.

---

## MODIFICATION 1 — DSM-48: Allow scrolling without mandatory recording

**Current behavior:** The `PageView` in `dsm48_encodage.dart` uses `NeverScrollableScrollPhysics()` when `_transcriptions[_currentIndex].isEmpty`, blocking the user from advancing until a voice recording is captured.

**Required change:** Remove this restriction. The user must always be free to swipe left or right to navigate between images, regardless of whether a recording has been made for the current image.

**Implementation:**
- Change the `PageView`'s `physics` property to always use `const BouncingScrollPhysics()` (or `const AlwaysScrollableScrollPhysics()`), removing the conditional based on `_transcriptions[_currentIndex].isEmpty`.
- Also update the right arrow `IconButton`'s `onPressed` so it is always enabled when `_currentIndex < _totalImages - 1`, removing the condition that requires `_transcriptions[_currentIndex].isNotEmpty`.
- Keep the existing "finish" button logic (last image still requires a transcription to enable the finish button — this constraint stays).
- The microphone and TTS flow should remain unchanged: the app still speaks the question and starts listening automatically when a page changes.

---

## MODIFICATION 2 — DSM-48: Change image scroll direction to right-to-left (French convention)

**Current behavior:** The `PageView` scrolls left-to-right (default Flutter behavior).

**Required change:** Images should advance from right to left — meaning the user swipes from right to left to go to the next image (like reading French text, or like a French clinical test booklet that goes from right to left page-by-page).

**Implementation:**
- Add `reverse: true` to the `PageView.builder` widget in `dsm48_encodage.dart`. This reverses the scroll direction so swiping left reveals the next image and swiping right goes back.
- Swap the left and right arrow icon buttons accordingly: the left arrow (`Icons.arrow_back_ios`) should now call `_nextPage()` and be disabled on the last image; the right arrow (`Icons.arrow_forward_ios`) should call `_previousPage()` and be disabled on the first image.
- Update the disabled conditions of both arrow buttons to match the new reversed logic.

---

## MODIFICATION 3 — DO-30: Allow scrolling without mandatory recording + add text input option

**Current behavior:** In `do30_test.dart`, the `PageView` uses `NeverScrollableScrollPhysics()`, completely blocking swipe navigation. The only way to advance is to speak a word (which sets `_hasHeardWord = true`) and then tap the "Next" button that appears.

**Required change:** The user must be able to advance to the next image in two ways:
1. **Voice answer** — speak the image name (existing STT flow), which sets `_hasHeardWord = true` and shows the "Next" button (keep existing behavior).
2. **Text answer** — type the image name in a text field (new feature).
3. **Skip / swipe** — the user can freely swipe to the next image with their finger at any time, even without answering. If the user swipes without answering, the transcription for that image remains empty and `_results[index]` stays `false` (counted as error/no answer).

**Implementation details:**

a) **Free swipe:** Change `PageView`'s `physics` to `const BouncingScrollPhysics()` unconditionally.

b) **Text input field:** Below the microphone icon area (inside the bottom `Container` of height 120), add a `TextField` where the user can type their answer. Use a `TextEditingController` (add `_textController = TextEditingController()` to state, dispose it in `dispose()`). Style it to match the existing teal/Cairo theme. Placeholder text should be the existing `loc.listening` string or a new key — use `"Écrire la réponse..."` as a fallback hint if no localization key exists.

c) **Text submission:** Add a small teal submit `IconButton` (use `Icons.send`) next to the text field. When tapped:
   - Take `_textController.text`, store it in `_transcriptions[_currentIndex]`.
   - Run it through the existing `_evaluateCurrentAnswer()` logic — but first set `_spokenText = _textController.text` so the evaluation method uses the typed text.
   - Clear the text field after submission.
   - Advance to the next page automatically after a 500ms delay (same as the existing voice flow), or if it is the last image, call `_finishTest()`.

d) **Coexistence:** Both voice and text input should work independently on every image. Whichever happens first (voice final result OR text submit) triggers the evaluation and auto-advance. If one input method has already evaluated the image, the other should be ignored (guard with a `_answered` boolean flag per image, or check `_transcriptions[_currentIndex].isNotEmpty`).

---

## MODIFICATION 4 — DO-30: Save results in the Word table format (additional export)

**Current behavior:** `_finishTest()` in `do30_test.dart` saves to Firestore with this metadata structure:
```dart
metadata: {
  'errors': _errors,
  'transcriptions': _transcriptions,
  'results': _results,
}
```

**Required change:** In addition to the existing save, also save a second structured metadata field called `'tableFormat'` that mirrors the DO-30 scoring table from the paper protocol. This table has the following columns for each of the 30 items:

| # | Réponse attendue (français) | Réponse attendue (arabe) | Réponse française (patient) | Réponse arabe (patient) |

**Implementation:**
- Add a new method `_buildTableFormat()` that returns a `List<Map<String, dynamic>>` with 30 entries.
- Each entry is a map with these keys:
  - `'numero'` → item number (1–30, int)
  - `'reponseAttendueFr'` → the first element of `_items[i].solutionsFr` (the canonical French answer)
  - `'reponseAttendueAr'` → the first element of `_items[i].solutionsAr` (the canonical Arabic answer)
  - `'reponsePatientFr'` → if `AppLocalizations.of(context).locale.languageCode != 'ar'`, use `_transcriptions[i]`, else `""`
  - `'reponsePatientAr'` → if `AppLocalizations.of(context).locale.languageCode == 'ar'`, use `_transcriptions[i]`, else `""`
  - `'correct'` → `_results[i]` (bool)
- Call this method inside `_finishTest()` and include its output in the Firestore save:

```dart
metadata: {
  'errors': _errors,
  'transcriptions': _transcriptions,
  'results': _results,
  'tableFormat': _buildTableFormat(),   // NEW
}
```

- The `_buildTableFormat()` method must be added to the `_Do30TestPageState` class. It should use `_items`, `_transcriptions`, `_results`, and the locale to build the list.

---

## GENERAL INSTRUCTIONS

- Preserve ALL existing logic, variables, localization calls (`AppLocalizations.of(context)`), imports, Firestore service calls, TTS/STT flows, animation controllers, and widget structure that are not explicitly modified above.
- Do not change the app's language, color scheme, or font (Cairo / teal theme).
- Do not introduce new packages or dependencies.
- Output the two complete modified Dart files: `do30_test.dart` and `dsm48_encodage.dart`.
- Each file must be complete, syntactically valid, and ready to drop into the project without further changes.
- Add a short `// MODIFIED:` comment on each line you change so the developer can review the diff easily.

---


