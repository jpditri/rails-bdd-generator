# Git Hooks

This directory contains git hooks to maintain code quality and prevent common issues.

## Installation

Run the installation script:
```bash
./bin/install-hooks
```

Or manually copy hooks:
```bash
cp .githooks/* .git/hooks/
chmod +x .git/hooks/*
```

## Available Hooks

### pre-commit
Runs before each commit to check for:
- Debugging statements (binding.pry, debugger, console.log)
- Migration safety issues
- Failing tests (for staged spec files)
- Large files (>1MB)
- Potential sensitive data (passwords, API keys, secrets)

### pre-commit-rubocop
- Auto-corrects style issues with RuboCop
- Re-stages corrected files automatically
- Prompts for manual review if issues remain

### pre-push
Runs before pushing to ensure:
- No pending migrations
- All tests pass (optional, set RUN_TESTS_ON_PUSH=true)
- No merge conflicts
- Bundle is up to date
- RuboCop checks pass

### commit-msg
Enforces conventional commit format:
- feat: New features
- fix: Bug fixes
- docs: Documentation changes
- style: Code style changes
- refactor: Code refactoring
- test: Test changes
- chore: Maintenance tasks
- perf: Performance improvements
- ci: CI/CD changes
- build: Build system changes
- revert: Reverting commits

## Bypassing Hooks

In emergency situations, you can bypass hooks:
```bash
git commit --no-verify
git push --no-verify
```

**Use with caution!** Hooks exist to prevent issues.

## Configuration

Environment variables:
- `RUN_TESTS_ON_PUSH=true` - Run full test suite on push
- `SKIP_RUBOCOP_HOOK=true` - Skip RuboCop auto-correct

## Troubleshooting

If hooks aren't running:
1. Check they're executable: `chmod +x .git/hooks/*`
2. Verify Git config: `git config core.hooksPath`
3. Re-run installation: `./bin/install-hooks`

## Contributing

To modify hooks:
1. Edit files in `.githooks/`
2. Run `./bin/install-hooks` to update
3. Test thoroughly before committing
