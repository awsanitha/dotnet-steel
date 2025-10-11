# Steel (.NET Solution Template)

A minimal, opinionated .NET 10 solution starter focused on **clarity, reproducibility, and fast feedback**. "Steel" is intended for developers who want a **lean starting point** for .NET apps and libraries with modern C# language features, centralized dependency management, reproducible builds, and a clean test setup using the emerging Microsoft Testing Platform with xUnit v3.

## Why This Template?

This repository refines the default `dotnet new` templates by layering in a small set of production‑minded conventions:

- **.NET 10 / C# 14 preview ready** via `global.json` + explicit `LangVersion` + suppression of preview banners.
- **Reproducible builds** using the `DotNet.ReproducibleBuilds` SDK (isolated mode) so builds are deterministic.
- **Central package management** (`Directory.Packages.props`) with transitive version pinning.
- **Treat warnings as errors** and latest analyzer rules (`AnalysisLevel=latest-all`).
- **Optimized build pipeline** (`OptimizeImplicitlyTriggeredBuilds=true`).
- **Modern test stack**: Microsoft Testing Platform runner + xUnit v3 + built‑in code coverage extension.
- **Locked dependency graph** using NuGet lock files (`RestorePackagesWithLockFile`).
- **Simple, readable structure**: `src/` and `tests/` only.

Use it when you need a trustworthy baseline before layering domain logic, additional projects (class libraries, web APIs), or CI/CD workflows.

## Project Structure

```
├── Directory.Build.props         # Shared build + analysis configuration
├── Directory.Packages.props      # Centralized package versions (CPM)
├── global.json                   # SDK + MSBuild SDK pinning + test runner
├── nuget.config                  # Clean, deterministic feed list
├── Steel.slnx                    # Solution (slnx format) grouping src/tests
├── src/
│   └── Steel.ConsoleApp/
│       ├── Steel.ConsoleApp.csproj
│       └── Program.cs            # Minimal entry point
└── tests/
    └── Steel.ConsoleApp.Tests/
        ├── Steel.ConsoleApp.Tests.csproj
        ├── UnitTest1.cs          # Placeholder test
        └── xunit.runner.json     # Runner config (copied to output)
```

## Features In Detail

### Minimal NuGet Feed Configuration (nuget.config)
The `nuget.config` intentionally does only two things:

1. `<clear />` wipes any inherited machine/user/global feeds to guarantee determinism.
2. Adds back a single trusted public source: `https://api.nuget.org/v3/index.json`.

Why this matters:
- Avoids "feed sprawl" where corporate mirrors, experimental feeds, or personal test sources silently influence restores.
- Ensures everyone resolves packages from the *same* index, making lock files reproducible across environments and CI.
- Reduces the surface for supply‑chain surprises (e.g., accidentally pulling a similarly named package from an internal feed first).
- Makes provenance audits simpler—only one external source to review.

Extending safely:
- If you must add a private feed, list it explicitly **below** nuget.org and document its purpose.
- Prefer authenticated feeds only when necessary; keep credentials out of the repo and supply them via environment variables or secure CI secrets.
- Re‑run `dotnet restore --locked-mode` after changes to confirm no unintended transitive shifts.

If your organization mandates a central mirror (Artifactory, Azure Artifacts, Nexus): replace the nuget.org entry *instead of* adding both, unless you intentionally need fallbacks. This keeps dependency provenance unambiguous.

### Locked Dependency Graph
NuGet lock filing (`packages.lock.json`) prevents accidental updates; commit the lock files for repeatable restores.

Why this matters:
- Guarantees repeatable restores in CI / dev environments.
- Makes dependency diffs explicit—surprises surface as lock file changes.
- Supports incident response (you can rebuild the exact dependency tree of a past artifact).
- Reduces flaky builds tied to upstream package changes.

### Reproducible Builds
Uses `DotNet.ReproducibleBuilds.Isolated`/`DotNet.ReproducibleBuilds` to embed deterministic build settings. This improves cacheability, supply chain trust, and consistent artifact hashes.

Why this matters:
- Deterministic outputs enable reliable caching (CI/CD, remote build systems) and binary reproducibility checks.
- Simplifies security / supply chain audits because the same source + toolchain yields identical artifacts.
- Reduces heisenbugs caused by timestamp or environment variance.

### Central Package Management (CPM)
`Directory.Packages.props` defines all allowed package versions. Individual project files simply reference packages without versions. This reduces drift and enables single‑point upgrades. Transitive pinning is enabled to avoid silently floating versions.

Why this matters:
- Single place to review and update dependencies lowers cognitive load.
- Prevents “version drift” across projects that leads to subtle runtime inconsistencies.
- Enables atomic dependency upgrade PRs with minimal, focused diffs.
- Transitive pinning avoids unplanned updates that could break builds unexpectedly.

### Analyzer + Code Style Enforcement
- `.editorconfig` codifies formatting, indentation, naming, and style preferences for consistent diffs across tools.
- `.globalconfig` elevates broad CA/Roslyn rules to errors for early design, performance & security feedback.
- `AnalysisLevel=latest-all` to adopt newest analyzer rules early.
- `TreatWarningsAsErrors=true` ensures quality gates fail fast.

Why this matters:
- Catches potential defects and style issues early—before code review.
- Keeps tech debt from accumulating silently (warnings cannot be ignored).
- Ensures consistency across contributors and automation (formatters / analyzers) reducing review churn.

### Testing Stack
- Microsoft Testing Platform runner (future‑proof vs legacy vstest).
- xUnit v3 test framework.
- Code coverage via `Microsoft.Testing.Extensions.CodeCoverage` (collects coverage without extra tooling).

Why this matters:
- Adopts next‑gen test runner architecture early, reducing future migration pain.
- xUnit v3 brings modern assertion + async improvements.
- Built‑in coverage minimizes external tooling/setup friction.
- Fast feedback loop encourages writing granular tests.


## Getting Started

Prerequisites:
- .NET SDK 10 (preview / RC) matching `global.json` (the repo pins `10.0.100-rc.1.25451.107`).

Clone and build:
```bash
git clone <your-fork-url>
cd dotnet-steel
dotnet restore
dotnet build
```

Run the console app:
```bash
dotnet run --project src/Steel.ConsoleApp
```

Run tests:
```bash
dotnet test
```

Generate (implicit) coverage report (coverage data collected automatically; for richer formats integrate a report tool like ReportGenerator afterward).

## Adding More Projects
Add a class library:
```bash
dotnet new classlib -n Steel.Core -o src/Steel.Core
```
Include it in the solution (either use `dotnet sln` or manually extend `Steel.slnx`). For `.slnx` you can add a block:
```xml
<Folder Name="/src/">
  <Project Path="src/Steel.Core/Steel.Core.csproj" />
  <!-- existing projects -->
</Folder>
```
Then reference it from the console app:
```bash
dotnet add src/Steel.ConsoleApp reference src/Steel.Core/Steel.Core.csproj
```

## Updating Dependencies
Edit `Directory.Packages.props`, bump versions, then:
```bash
dotnet restore
# If it fails due to version change, regenerate lock files:
dotnet restore --force-evaluate
```
Commit the updated lock files under each project directory.

## Recommended Continuous Integration
Minimal GitHub Actions workflow idea:
```yaml
name: build
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '10.0.100-rc.1.25451.107'
      - run: dotnet restore --locked-mode
      - run: dotnet build --configuration Release --no-restore
      - run: dotnet test --configuration Release --no-build
```
(Adjust coverage collection if adopting different tooling.)

## Customization Ideas
- Rename solution and projects
- Add `Directory.Build.targets` for publishing / packaging conventions.
- Introduce `src/Steel.Infrastructure`, `src/Steel.Domain` for layered architecture.
- Add Roslynator packages (centrally) if you need stricter style rules.
- Integrate `dotnet format` in CI for consistent formatting.
- Add a `README` badge set (build, coverage, license) once CI is live.

## Dev Container
This repo ships with a `.devcontainer` configuration for consistent, ready-to-code environments.

What it provides:
- Base image: `mcr.microsoft.com/devcontainers/base:noble` plus the .NET 10 SDK (via feature) and ASP.NET Core 9 runtime (for tooling needs).
- Extensions pre-installed: `ms-dotnettools.csdevkit`, RESX editor, EditorConfig support.
- Environment hardening: telemetry disabled (`DOTNET_CLI_TELEMETRY_OPTOUT=true`), no logo noise.
- Volume mount for X.509 stores to persist dev cert trust across rebuilds.
- Automatic workload update on create, dev HTTPS cert provisioning & `dotnet tool restore` on start.

Benefits:
- Eliminates "works on my machine" drift (SDK + workloads pinned once).
- Faster onboarding: open in VS Code and start building/testing immediately.
- Reproducible analyzer + test behavior inside and outside CI.

Usage:
1. Install VS Code + Dev Containers extension (or use GitHub Codespaces).
2. Open the repository and when prompted choose "Reopen in Container".
3. After build, run `dotnet test` or `dotnet run` as usual.

To customize, edit `.devcontainer/devcontainer.json` (add features, extensions) or introduce a Dockerfile if you need OS-layer packages.

## Troubleshooting
- Preview SDK warnings: Already suppressed by `SuppressNETCoreSdkPreviewMessage`.
- Locked restore errors: Run `dotnet restore --force-evaluate`.
- Analyzer failures: Treat them as quality gates—fix or suppress explicitly with justification.

## License
Specify a license (e.g., MIT) by adding a `LICENSE` file—currently unspecified.

## Contributing
Fork, branch (`feat/your-feature`), open PR. Keep changes small; ensure `dotnet test` passes and no new analyzer warnings.

---
Generated README scaffold. Tailor messaging (company name, internal guidelines, license) before publishing.
