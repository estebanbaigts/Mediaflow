# Contributing

Thank you for helping. MediaFlow handles people's only copy of their work, so
the bar for correctness is high.

## Ground rules

1. **No feature may delete, move or overwrite a user file.** Not behind a
   flag, not "with confirmation" in v0.x.
2. Heuristics never become proof. Only equal SHA-256 digests mean identical.
3. Every state change goes through `state.rs`. Never mark an operation `done`
   without verification.
4. The engine re-validates paths and grants at execution time. The UI never
   sends paths.
5. Errors are shown to users through `MfError::user_message()` — write them
   for someone who is not technical.

## Repository layout

```
crates/
  mediaflow-core/     engine: scan, plan, verified copy, journal, compare
  mediaflow-cli/      `mediaflow` command-line tool
apps/
  desktop/            Tauri 2 shell (src-tauri/) and React UI (src/)
  macos-widget/       WidgetKit extension and its StatusKit Swift package
docs/                 architecture, threat model, guides, release procedures
scripts/              build and packaging scripts
.github/workflows/    CI and release
```

Rust code shared by the CLI and the app lives in `mediaflow-core`; the apps
only wire it to a user interface.

## Branches

`main` is always releasable. Work happens on short-lived branches named
`<type>/<topic>` (`feat/`, `fix/`, `docs/`, `chore/`, `ci/`), merged through
a pull request once CI is green.

## Workflow

```sh
cargo fmt --all && cargo clippy --all-targets -- -D warnings
cargo test --workspace --exclude mediaflow-app
cd apps/desktop && npm ci && npx tsc --noEmit && npm test
```

- Tests that create or damage files must use `tempfile` directories and
  generated data (`tests/common`). Never point tests at real folders.
- A bug fix comes with a test that fails before the fix.
- Database changes = a new numbered migration in `db.rs`; never edit an
  existing one.
- New dependencies: explain why in the PR, check licence (MIT/Apache/BSD
  compatible) and maintenance.
- New Tauri command: add it to `apps/desktop/src-tauri/build.rs` and the
  capability file, and take ids, not paths.

## Commit messages

Imperative mood, one topic per commit. Mention user-visible changes in
`CHANGELOG.md`.
