# Contributing to Enhanced Vehicle Squared

Enhanced Vehicle Squared is maintained in this repository. Do not send changes
to the archived original project on this project's behalf.

## Language

Use clear English for code comments, commits, issues, pull requests, UI text,
test names, test output, documentation, and release notes. The distributed mod
is English only.

## Before opening a pull request

1. Start from the current `main` branch.
2. Keep each change focused and preserve the documented technical compatibility
   identifiers unless the change includes an approved migration plan.
3. Add or update regression coverage for behavior changes.
4. Run:

   ```sh
   LUA=lua5.1 LUAC=luac5.1 scripts/validate.sh
   ```

5. Run `git diff --check` and review the production ZIP contents.

Changes that affect installed-game behavior require licensed acceptance before
release. Maintainers run that suite because it depends on locally licensed
Farming Simulator files. Genuine multiplayer validation is tracked separately.

## Compatibility rules

Do not casually rename the production ZIP, action identifiers, configuration
path, savegame keys, specialization, event schema, or public Lua globals. Those
old-prefixed names are compatibility interfaces used by existing players and
other mods; they are not active project branding.

## Release contents

Only files listed in `scripts/runtime-files.txt` enter the production ZIP.
Tests, scripts, screenshots, logs, and finalisation records must remain outside
the release archive. `LICENSE` and `ATTRIBUTION.md` must be included.

## License

Contributions are accepted under the project's
[CC BY-NC-SA 4.0 license](LICENSE). By contributing, you confirm that you may
submit the work under that license. Preserve required attribution and identify
adapted material where applicable.
