---
name: wr-tdd:setup-tests
description: Set up a test framework for the project. Examines the codebase, recommends a test runner, configures package.json, and creates an example test.
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# Test Framework Setup

Configure a test framework for this project so TDD enforcement can operate. The TDD hooks require a working `test` script in package.json to run the Red-Green-Refactor cycle.

## Steps

### 1. Discover project context

Examine the project to understand what needs testing.

**Find the tech stack**:
- Read `package.json` for dependencies, devDependencies, and existing scripts
- Check for TypeScript (`tsconfig.json`, `.ts` files)
- Check for React/Next.js/Vue/Svelte (framework-specific testing needs)
- Check for existing test infrastructure (vitest.config.*, jest.config.*, etc.)
- Check for existing test files (`*.test.*`, `*.spec.*`, `__tests__/`)

**Assess what exists**:
- If test files already exist but no test script: just wire up the script
- If a test runner is installed but not configured: configure it
- If nothing exists: recommend a test runner and set up from scratch

### 2. Choose a test runner

Based on the project's stack, recommend the best test runner:

| Stack | Recommended Runner | Why |
|-------|-------------------|-----|
| Vite/Vitest already installed | Vitest | Already in deps |
| Next.js / React | Vitest | Fast, ESM-native, good React support |
| TypeScript project | Vitest | No compile step needed |
| Plain Node.js | Node.js built-in test runner | Zero dependencies |
| Existing Jest setup | Jest | Don't switch if already configured |

Prefer Vitest for most modern projects. It's fast, needs minimal config, and works with TypeScript and JSX out of the box.

### 3. Confirm with the user

You MUST use the AskUserQuestion tool before making changes.

Present:
1. What you found (existing test infrastructure, if any)
2. The recommended test runner and why
3. What files will be created/modified
4. Whether they want an example test created

### 4. Install and configure

Based on user confirmation:

**If Vitest:**
```bash
npm install -D vitest
```

Add to package.json scripts:
```json
"test": "vitest run"
```

Create `vitest.config.ts` if needed (minimal config, only what's required).

**If Node.js built-in:**
Add to package.json scripts:
```json
"test": "node --test"
```

**If Jest:**
```bash
npm install -D jest @types/jest ts-jest
```

Configure as needed for the project's TypeScript/JSX setup.

### 5. Create example test (optional)

If the user wants an example test, create one that:
- Tests an existing function or component in the project
- Follows the project's file structure conventions
- Demonstrates the testing pattern (describe/it/expect)
- Is intentionally minimal (the user will write real tests)

Place it next to the source file it tests, using the `.test.ts` or `.test.tsx` convention.

### 6. Verify

Run the test command to confirm it works:
```bash
npm test
```

If it fails, diagnose and fix the configuration. The test script must work before TDD enforcement can operate.

### 7. Report

Tell the user:
- What was installed and configured
- How to run tests (`npm test`)
- That TDD enforcement is now active (implementation edits require tests first)
- The Red-Green-Refactor workflow they'll follow

$ARGUMENTS
