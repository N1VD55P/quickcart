# Reproducible evidence commands

Run these commands from the repository root. Save the output in this folder
and record the date and Flutter version in the evidence index.

```bash
flutter --version
flutter test > Cartify_Evidence/evidence_flutter_test.txt
flutter analyze > Cartify_Evidence/evidence_flutter_analyze.txt
flutter devices > Cartify_Evidence/evidence_devices.txt
git log --oneline --all > Cartify_Evidence/evidence_git_history.txt
```

For an Android build:

```bash
flutter build apk --debug
```

Record the APK path, build date, device model and Android version. Do not copy
`build/` output into this evidence folder or commit generated APKs unless the
submission explicitly requires one.

## Interpreting the current outputs

- `evidence_flutter_test.txt` records 35 passing tests.
- `evidence_flutter_analyze.txt` records analysis output with informational
  lints and warnings; it should not be described as "zero issues".
- `evidence_devices.txt` records the device detected when the command ran.
