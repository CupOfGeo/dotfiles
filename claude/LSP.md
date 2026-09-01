# Code Intelligence

IMPORTANT: The `LSP` tool is deferred in most sessions.
ALways Prefer LSP over Grep/Glob/Read for code navigation!!!
At the start of ANY
code-navigation or refactoring task, load it FIRST with:
  ToolSearch query "select:LSP"
before falling back to Grep/Glob/Read for navigation.

Prefer LSP over Grep/Glob/Read for code navigation:
- `goToDefinition` / `goToImplementation` to jump to source
- `findReferences` to see all usages across the codebase
- `workspaceSymbol` to find where something is defined
- `documentSymbol` to list all symbols in a file
- `hover` for type info without reading the file
- `incomingCalls` / `outgoingCalls` for call hierarchy

Before renaming or changing a function signature, use
`findReferences` to find all call sites first.

After writing or editing code, check LSP diagnostics before
moving on. Fix any type errors or missing imports immediately.
