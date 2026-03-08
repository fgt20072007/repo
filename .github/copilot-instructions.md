
# Copilot Engineering Rules (Roblox / Rojo / Luau)

These instructions are **general and repo-aware**: follow the project’s *existing* structure and conventions in the current repository.

---

## Structural priority (MOST IMPORTANT)
Code organization and structural clarity are the highest priority.

- Always prioritize clean, hierarchical structure over cleverness.
- Group related logic by domain, not by convenience.
- One responsibility per module.
- Avoid large monolithic files.
- Folder structure must reflect architectural boundaries (Server / Client / Shared or equivalent in the repo).
- Public surface must be minimal and intentional.
- Internal implementation must remain encapsulated.
- Code should be readable top-to-bottom with clear separation between:
  - Public API
  - Private/Internal logic
  - State
  - Side-effects
- Prefer explicit structure over implicit magic.

If a solution works but breaks structural clarity, refactor it.

---

## 1) Hard prohibitions
- **No `print`, `warn`, `assert`, or `error()` for control-flow.**
  - For debugging or instrumentation, use the official Roblox `debug` library (https://create.roblox.com/docs/reference/engine/libraries/debug).
  - Prefer structured instrumentation such as `debug.profilebegin()` / `debug.profileend()` for scoped profiling.
  - Do not introduce custom logger utilities unless explicitly requested.
- **No TODO/FIXME notes, no placeholder comments, no “notes to self”.**
- **No new frameworks/abstractions.** Use what already exists in the repo.
- **No direct `RemoteEvent`/`RemoteFunction` usage.** Use the repo’s approved networking wrapper.

- **Do not invent a new folder layout.** Structure is critical. Before creating files, locate the closest existing module of the same kind and mirror its folder hierarchy, naming conventions, and structural patterns exactly.
- If the repo has **Server / Client / Shared** separation:
  - Server-only code goes under the repo’s server root.
  - Client-only code goes under the repo’s client root.
  - Shared code goes under the repo’s shared/common root and must not require server-only modules.
- If the repo uses `Public` and/or `_Internal`:
  - Put **state, validation, indexes/registries, reducers/mutators, network handlers** in `_Internal`.
  - Keep the public facade minimal (e.g. `init.lua` or `<Name>Service.lua`) and expose only stable APIs.
  - Never require `_Internal` from outside the owner module.
- **Never move files** unless explicitly requested.
- If multiple locations seem plausible, choose the one that matches the nearest existing pattern and keep the change minimal.

## 2) Architecture invariants (apply to all repos)
- **Server-authoritative.** The server owns truth; clients submit requests.
- **Ownership & encapsulation.** The owner module creates, validates, and mutates its state. Never return mutable internal references.
- **Idempotent lifecycle.** `Init()`/`Start()` (if used) must be safe to call multiple times.
- **Dependencies are explicit and directional.** No circular coupling.

## 3) Networking & security
- All client inputs must be validated:
  - **Type validation** (strict/defensive)
  - **Ownership/permission validation** (player owns the thing they’re acting on)
  - **State validation** (action is legal in current state)
  - **Rate limiting** (token/leaky bucket or existing limiter)
- Handlers must be **spam-resistant** and **side-effect safe** (don’t duplicate effects on retries).

## 4) Concurrency & lifecycle
- Assume concurrent signals/events.
- Prefer event-driven patterns (Signals) over polling.
- Cleanup is mandatory (Maid/Janitor).
- Promises only for real async boundaries (IO, DataStore, deliberate yields).

## 5) Performance discipline
- Avoid per-frame work unless necessary.
- Prefer O(1) access patterns (maps/indexes) over repeated scans.
- Avoid `WaitForChild` in hot paths.


## 6) Coding standard (Luau)
- Use `--!strict` when the repo uses strict typing.
- Prefer small, composable functions; single responsibility.
- Validate early, return early; keep happy-path readable.
- Match existing naming/style (PascalCase vs camelCase, `init.lua` pattern, etc.).

---

## 6.5) Advanced type system requirements (Luau)
Types are part of the architecture. Prefer type-first design for shared/public surfaces.

- Prefer **explicit type contracts** for public APIs (services, modules, networking routes).
- Avoid `any` and overly broad types. Use `unknown` + narrowing when needed.
- Prefer **generic abstractions** over duplicated concrete implementations when the API is reused.
- Use **generic type aliases** and **parametric polymorphism** where it improves correctness.
- Use **type packs** (`T...`) when modeling variadic arguments (especially for networking and callbacks).
- Networking must be **compile-time type-safe**:
  - Route definitions must encode argument/return shapes in types.
  - Client/server handlers must agree on the contract through shared types.
- Encode invariants in types when practical (e.g., branded types for IDs, constrained unions for states).
- Keep type complexity proportional:
  - Use advanced typing for **Shared contracts, Net routes, Data models, public surfaces**.
  - Do **not** introduce “type gymnastics” for small one-off scripts.
- Do not introduce new type-heavy helper frameworks. Use patterns already present in the repo.

## 7) When uncertain
- If you cannot confidently determine the correct folder/module pattern from existing code, **do not guess**. Ask for the intended location or present 2 options with brief reasoning.