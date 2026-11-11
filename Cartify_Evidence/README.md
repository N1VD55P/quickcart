# Cartify evidence package

This folder contains reproducible evidence for claims made in the Cartify
academic reports and README. It separates automated evidence from manual
screenshots and Firebase Console records.

## How to use

1. Run the commands in [evidence_commands.md](evidence_commands.md).
2. Record each manual test in [manual_test_record.md](manual_test_record.md).
3. Add screenshots and screen recordings under the local `screenshots/`
   folder. That folder is ignored by Git because screenshots may contain
   email addresses, project identifiers or other private data.
4. Complete [evidence_index.md](evidence_index.md) with the final filenames,
   date, device and result.
5. Export the completed index and test records as PDF for submission.

Do not store passwords, service-account keys, access tokens or
`google-services.json` in this folder.

## Evidence status

The committed text files are command outputs captured from this project.
Manual evidence is marked as a placeholder until screenshots or recordings
are added by the tester.
