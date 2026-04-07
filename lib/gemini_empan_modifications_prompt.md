# Gemini Flash Agent Prompt — Empan Direct Test Modifications

---

## CONTEXT

You are a Flutter/Dart expert modifying a single file: **`empan_direct.dart`**.

This file implements the **Empan Direct** (direct digit span) cognitive test. The test plays a sequence of digits aloud to a patient, then asks the patient to repeat them back either by speaking or using an on-screen numpad dialog. There are 14 sequences of increasing length. The patient gets 2 attempts per sequence.

You are also given **`tmt_a_page.dart`** as a reference file — do NOT modify it. Use it only to understand the pattern for the "finish test early" AppBar button (a `TextButton.icon` with a stop icon and a localized label placed in the `AppBar.actions`).

Read both files carefully. Then apply ALL three modifications described below.

---

## MODIFICATION 1 — Add an AppBar "Finish Test Early" button (same pattern as TMT-A)

**Current behavior:** There is already a red `ElevatedButton` labeled `AppLocalizations.of(context).finishTest` at the bottom of the screen that calls `_showFinalScore()`. This works but forces the examiner to scroll down and is not immediately visible.

**Required change:** Add a second "finish" entry point in the AppBar, following exactly the same pattern used in `tmt_a_page.dart`.

**Implementation:**

Look at `tmt_a_page.dart`'s `AppBar`. It has an `actions` list containing a `Padding` > `TextButton.icon` with:
- `icon: Icon(Icons.stop_circle_outlined, color: Colors.red)`
- `label` text styled with `GoogleFonts.cairo`, color red, fontWeight bold
- `onPressed`: in TMT-A it calls `Navigator.pop(context)`. In Empan Direct, it must instead call `_showFinalScore()` — which already saves the current partial score and shows the summary dialog.

Add this exact same `TextButton.icon` structure to the `AppBar.actions` list in `empan_direct.dart`.

For the label text: use `AppLocalizations.of(context).finishTest` — the same localization key already used by the existing bottom red button. This automatically gives the correct Arabic text in Arabic mode and French text in French mode. Do NOT hardcode any text string.

**Result:** The examiner can tap this button at any point (e.g., after sequence 4/14) to stop the test, save the partial score, and show the summary. The existing bottom red button stays as-is.

---

## MODIFICATION 2 — Hide the "Expected" row in the debug info box; replace with "Tapped" when numpad is used

**Current behavior:** At the bottom of the main screen, when `_spokenText` or `_accumulatedDigits` is not empty, a grey `Container` appears showing three rows:
```
🎤 STT: <spokenText>
🔢 Mapped: <accumulatedDigits>
✅ Expected: <correct answer digits>
```

The **"Expected"** row reveals the correct answer to the patient. This must be hidden from the patient at all times.

When the patient uses the **numpad dialog** (`_showManualInputDialog()`), the `_spokenText` is set to `"manual: XXXX"` where XXXX is what they typed. This is also shown raw to the patient.

**Required changes:**

**a) Remove the `✅ Expected:` row entirely** from the grey debug container. Delete that specific `Text` widget. The container should now show only two rows (STT and Mapped), or be redesigned per point (b) and (c) below.

**b) Rename/relabel the rows for patient-friendliness:**
- `🎤 STT: <spokenText>` → keep as-is only when NOT in manual mode (i.e., `_spokenText` does NOT start with `"manual:"`).
- When `_spokenText.startsWith("manual:")` is true, replace the STT row with: `⌨️ Tapped: <accumulatedDigits>` using the same `GoogleFonts.cairo(fontSize: 12)` style. This shows the patient what they typed on the numpad, using a clear keyboard icon instead of a microphone icon.
- The `🔢 Mapped: <accumulatedDigits>` row should remain visible in both cases as a second confirmation row.

**c) Wrap all remaining rows conditionally:**
- The entire grey container is only shown when `_spokenText.isNotEmpty || _accumulatedDigits.isNotEmpty` — this condition stays unchanged.
- Inside the container, apply the conditional rendering described in (b).

**Summary of what the box should look like after this change:**

*Voice mode (normal STT):*
```
🎤 STT: <spokenText>
🔢 Mapped: <accumulatedDigits>
```

*Numpad mode (manual input):*
```
⌨️ Tapped: <accumulatedDigits>
🔢 Mapped: <accumulatedDigits>
```

*(The Expected row is gone in both cases.)*

---

## MODIFICATION 3 — Fix the "انتهيت" (done listening) button to use localization

**Current behavior:** When `_isListening` is true, a button appears with the hardcoded Arabic label `'انتهيت'` and calls stop on the STT. This label is always Arabic regardless of the app language.

**Required change:** Replace the hardcoded string `'انتهيت'` with `AppLocalizations.of(context).finishTest` — the same localization key used elsewhere for finishing/confirming. This ensures the button reads correctly in both French and Arabic modes.

Keep all other properties of that button (color, icon, shape, padding, `onPressed`) exactly as they are.

---

## GENERAL INSTRUCTIONS

- Preserve ALL existing logic, variables, timers, STT/TTS flows, animation controllers, Firestore calls, localization calls, and widget structure that are not explicitly modified above.
- Do not add new packages or imports.
- Do not change the scoring logic, sequence list, or navigation flow.
- Add a short `// MODIFIED:` comment on each line you change so the developer can review the diff easily.
- Output the single complete modified file: `empan_direct.dart`.
- The file must be complete, syntactically valid Dart/Flutter code, ready to drop in without further changes.

---

## INPUT FILES

You will receive:
1. `empan_direct.dart` — the file to modify
2. `tmt_a_page.dart` — reference only for the AppBar button pattern (do not modify)

Apply all three modifications and return the complete updated `empan_direct.dart`.
