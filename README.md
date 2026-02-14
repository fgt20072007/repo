# Engineering, Security & Architecture Rules (Rojo / Roblox Studio)

---

## Core Architectural Principle
This project implements a **server-authoritative, modular internal framework** built on Rojo, with strict ownership boundaries, lifecycle governance, and dependency control.

The system is not just modular — it operates on top of a controlled internal service framework.

---

# Architecture Model

## Modular Service-Oriented OOP with Hierarchical Composition

Each domain is implemented as an encapsulated Service:

InventoryService
  ├── Public
  ├── _Internal
  └── InventoryService.lua

Services are owners of their state and expose minimal public APIs.

---

# Encapsulation & Ownership

## Public Surface (Strict Contract)
A Service may only expose:
- Init() → idempotent
- Start() → idempotent
- Minimal, stable public API

Rules:
- Never expose internal state.
- Never return mutable internal references.
- All mutations must occur inside the owner.
- Public API is small, stable, and explicit.

---

## Private Implementation (_Internal)

All internal logic must live inside `_Internal/*`.

Includes:
- State
- Validation
- Registries / indexes
- Reducers / mutators
- Networking handlers

Rules:
- `_Internal` is never required externally.
- State may only be mutated by its owner.
- No cross-module state access.

---

## State Ownership Model
Owner = module that creates, validates, and mutates the state.

Rules:
- Single owner per state domain.
- No state duplication.
- No bidirectional coupling.
- Services interact only via public contracts.

---

# Internal Service Framework

The project uses a centralized service framework.

## BaseService (Abstract Layer)
All Services must implement BaseService contract.

Responsibilities:
- Init guard (idempotent)
- Start guard (idempotent)
- Automatic Maid/Janitor lifecycle management
- Lifecycle validation
- Registration into ServiceRegistry

No Service may bypass lifecycle control.

---

## ServiceRegistry (Centralized Lifecycle Control)

The Registry is responsible for:
- Registering Services
- Resolving declared dependencies
- Detecting circular dependencies
- Executing Init() in topological order
- Executing Start() only after full initialization
- Preventing duplicate instances

Rules:
- Services may only access other Services via the Registry.
- Dependencies must be declared explicitly.
- No direct cross-service requires.

---

# Dependency Governance

- Dependencies must be unidirectional.
- Circular dependencies are prohibited.
- Services may consume only Public contracts of other modules.

---

# Networking & Security

- Server-authoritative always.
- No direct RemoteEvent/RemoteFunction usage.
- Only use approved networking wrapper (Red / Zap / Packets).
- All client input must be validated (type, ownership, state, rate limits).
- Handlers must be idempotent and spam-resistant.

---

# Concurrency & Synchronization

- Assume concurrent execution.
- All lifecycle methods must be reentrancy-safe.
- Use event-driven architecture (Signals).
- Mandatory Maid/Janitor cleanup.
- Promises only for real async boundaries (IO, DataStore, heavy yield).

---

# Performance Discipline

- No per-frame unnecessary work.
- Prefer O(1) structures over O(n).
- Cache expensive lookups.
- No WaitForChild in hot paths.
- Avoid polling; prefer event-driven systems.

---

# Advanced Patterns (When Justified)

Allowed when measurable benefit exists:
- ECS (Jecs) for high-entity systems
- FSM for complex behavior
- Command / Transaction pattern for validated actions
- Centralized rate limiting (token/leaky bucket)
- Caching & indexing strategies
- Replication layer only for render-facing state
- Interface contracts with types for public APIs

If used, architectural benefit must be explicit.

---

# Initialization Flow

1. Register all Services
2. Resolve dependency graph
3. Execute Init() in topological order
4. Execute Start() after full initialization

Partial initialization is not allowed.

---

# Architectural Standard

This codebase follows a controlled internal service framework with strict encapsulation, lifecycle governance, dependency direction, and ownership boundaries.

The application layer lives on top of this framework.
Services do not self-manage outside centralized lifecycle control.