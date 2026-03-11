# Repository Guidelines

## Project Structure & Module Organization
`src/` contains the Python application entrypoint (`src/main.py`), orchestration logic, AI clients, scrapers, and storage helpers. Generated summaries are written to `data/summaries/`, while the published site lives under `docs/` with Jekyll posts in `docs/_posts/` and API metadata in `docs/api/`. Unit tests are in `tests/`. The Flutter client is isolated in `mobile/horizon_mobile/` and should be treated as a separate app when changing mobile behavior.

## Build, Test, and Development Commands
Install dependencies with `uv sync`. Run the pipeline locally with `uv run horizon --hours 24` or another time window such as `uv run horizon --hours 48`. Use `python -m unittest tests.test_manifest` for the current regression test suite. The helper script `./scripts/daily-run.sh` updates dependencies, runs Horizon, and prepares a `gh-pages` deployment flow; use it only when you intend to publish generated docs.

## Coding Style & Naming Conventions
Target Python 3.11+ and keep code consistent with the existing style: 4-space indentation, type hints on non-trivial functions, and short module docstrings. Use `snake_case` for functions, variables, and modules; use `PascalCase` for classes like `HorizonOrchestrator`. Keep new modules focused by responsibility (`src/scrapers/`, `src/ai/`, `src/storage/`) and prefer explicit errors over silent fallbacks. When adding config or environment wiring, follow the existing `.env` and `data/config.json` pattern instead of hardcoding values.

## Testing Guidelines
Add tests under `tests/` using `test_*.py` filenames. Follow the current `unittest` style unless the repository adopts another framework in the future. Cover output-shaping logic, storage helpers, and manifest generation with deterministic fixtures or temporary directories. Run the affected test module locally before opening a PR.

## Commit & Pull Request Guidelines
Recent history follows short conventional prefixes such as `fix:`, `refactor:`, and `translate:`. Keep commit subjects imperative and scoped to one change, for example `fix: normalize manifest URLs`. Pull requests should explain the user-visible impact, note any config or workflow changes, and include screenshots when modifying `docs/` output or the Flutter UI. Link the relevant issue when one exists, and mention the commands you used to verify the change.

## Security & Configuration Tips
Never commit API keys or populated `.env` files. Keep secrets in environment variables referenced by `data/config.json` and GitHub Actions secrets. If a change affects publishing, confirm `HORIZON_PUBLIC_BASE_URL` and generated files in `docs/api/manifest.json` remain valid.
