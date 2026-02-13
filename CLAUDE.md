# Claude Code Instructions for Arrow Framework

This file contains instructions and context for Claude Code when working on the Arrow framework.

## Project Overview

Arrow is an opinionated, Express-inspired Dart server framework for rapid REST API development. It's designed for the 80-90% use case where you need a standard JSON REST API with minimal boilerplate.

**Current Status**: ~40-50% feature-complete compared to modern frameworks (Express, Hono, Gin, Echo)

**Active Development**: Following a 12-week modernization plan to bring Arrow to feature parity with modern frameworks. See `docs/modernization-plan.md` for details.

## Repository Structure

This is a git submodule within the `dart-wrap` monorepo workspace:
- Parent repo: `dart-wrap` (wrapper/workspace for Dart packages)
- This repo: `arrow` (the core framework)
- Sibling: `arrow_example` (example applications)

## Branch Strategy

**Active Branches:**
- `main` - Stable, production-ready code (GitHub default branch)
- `dev` - Active development branch with latest features

**Workflow:**
1. Work on `dev` branch for all modernization tasks
2. Create short-lived feature branches from `dev` for each task:
   - Naming: `feature/<task-name>` (e.g., `feature/add-patch-head-methods`)
   - Lifespan: 1-5 days maximum
   - Scope: Single task from modernization plan
3. Merge feature branches back to `dev` quickly
4. Merge `dev` → `main` periodically for stable releases

**Parked Branches** (future consideration):
- `parked/mcp-generator` - MCP server generation package
- `parked/openapi-codegen` - OpenAPI spec → Dart code generation
- `parked/openapi-spec-generator` - Dart code → OpenAPI spec generation

These contain experimental work on separate generator packages. Don't modify or merge these until packaging strategy is decided.

**Archived Branches** (historical reference only):
- `archive/2021-openapi-wip` - 4+ year old experimental OpenAPI work

## Development Principles

From the modernization plan:

1. **Test as we develop** - Write tests alongside features, not after
2. **Document as we develop** - Add Dart docs and guides with each feature
3. **Build on existing code** - Extend and improve rather than replace
4. **Stay opinionated** - Maintain Arrow's 80-90% use case focus

## Key Files

- `docs/modernization-plan.md` - 12-week plan for bringing Arrow to feature parity
- `docs/assessment.md` - Framework assessment and current state
- `docs/http-server-testing-solution.md` - Testing infrastructure notes
- `README.md` - Main project documentation

## Modernization Plan Phases

**Phase 1** (Weeks 1-3): Critical REST API Features
- HTTP methods, query helpers, validation, error handling, cookies

**Phase 2** (Weeks 4-6): Production Features
- File uploads, static files, rate limiting, security, compression

**Phase 3** (Weeks 7-10): Advanced Features
- Flexible responses, streaming, WebSockets, timeouts, graceful shutdown

**Phase 4** (Weeks 11-12): Polish & Examples
- Comprehensive tests, documentation, example projects

## What's Out of Scope

These are intentionally excluded from core framework:
- Template rendering (API-focused framework)
- Database integrations (user choice)
- ORM/query builders (user choice)
- GraphQL support (separate package)
- OpenAPI generation (separate `arrow_openapi` package)
- MCP server generation (separate `arrow_mcp_generator` package)

## Git Workflow Notes

- **Always work from `dev` branch** unless explicitly instructed otherwise
- **Feature branches should be atomic** - one task from the plan per branch
- **Commit frequently** with clear messages
- **Don't force push** without explicit user permission
- **Ask before destructive operations** (deleting branches, force pushing, etc.)

## Testing

- Write tests alongside each feature (not after)
- Fix HTTP server test timeout issue is a known blocker
- Target: 100+ passing tests, >80% code coverage
- Each feature should have unit tests and integration tests

## Documentation

- Add Dart docs to all public APIs as you write code
- Update README for major features
- Add guides to docs/ directory for complex features
- Include practical examples in documentation

## Notes

- This project was reorganized on 2026-02-13
- Several stale branches were archived/parked during cleanup
- Focus is on core framework modernization
- Generator packages (MCP, OpenAPI) are parked for future packaging decisions
