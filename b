# 05 — Modular Monolith

> [!NOTE] INSTRUCTIONS
> This is the default architecture of this framework — see
> [`ADR-001`](./decisions/records/ADR-001-modular-monolith-as-default.md).
> The diagram below uses the Attendance modules documented in
> `../02-domain/module-boundaries.md`. Delete this block once those module
> boundaries have been verified against the real backend structure.

## What it is

Attendance uses a **modular monolith**: one Spring Boot application that is
built, deployed, and released as a single unit, while keeping the main business
areas separated into modules.

The current documented modules are:

- `identity`
- `academic`
- `class-sessions`
- `attendance`

Each module owns its responsibilities and must communicate with other modules
through their public API instead of accessing internal implementation details.

The module boundaries are defined in
[`../02-domain/module-boundaries.md`](../02-domain/module-boundaries.md).

## One deployment, four modules

```mermaid
flowchart TB

    subgraph APP["Single deployable — Spring Boot application"]

        ID["identity<br/>Public API"]
        AC["academic<br/>Public API"]
        CS["class-sessions<br/>Public API"]
        AT["attendance<br/>Public API"]

        AC -->|"public API"| ID
        CS -->|"public API"| AC

        AT -->|"public API"| ID
        AT -->|"public API"| AC
        AT -->|"public API"| CS
    end

    DB[("PostgreSQL<br/>One relational database")]

    APP --> DB
```

The diagram represents one backend deployment and one relational database.

The arrows represent allowed dependencies between modules. They must remain
consistent with
[`../02-domain/module-boundaries.md`](../02-domain/module-boundaries.md).

For example, the `attendance` module may obtain information from
`class-sessions`, `academic`, or `identity` through their public APIs, but it
must not access their internal implementation directly.

## Anatomy of a module

| Part | Rule |
|---|---|
| Public API | The functionality that another module is allowed to use |
| Internal | Application, domain, and persistence implementation that belongs only to the module |
| Owned data | Data that the module is responsible for creating and modifying |
| Tests | Unit tests verify internal rules and integration tests verify module behavior |

For Attendance, a module may contain the layered responsibilities documented in
[`./layered-architecture.md`](./layered-architecture.md).

## How modules communicate inside one process

| Mechanism | Use it when | What it is not |
|---|---|---|
| Public API call | One module needs information or behavior from another module immediately | It is not a network request; the modules run inside the same Spring Boot application |
| In-process event | Multiple parts of the application need to react to an action that has already occurred | It is not an external message broker or separate service |

The current Attendance architecture primarily relies on direct module
interaction through controlled public boundaries.

For example:

```text
Student scans QR
        |
        v
attendance
        |
        +----> class-sessions public API
        |
        +----> identity public API
        |
        v
Attendance record
```

The `attendance` module coordinates the check-in, while information owned by
other modules is obtained through their public boundaries.

## Database ownership

Attendance uses one PostgreSQL database as part of the same deployable
application.

Although the database is shared physically, each module should be responsible
for the data that belongs to its business area.

| Module | Main responsibility |
|---|---|
| `identity` | Users, authentication, and roles |
| `academic` | Courses and academic information |
| `class-sessions` | Class sessions and temporary QR information |
| `attendance` | Student attendance and check-in records |

A module should not modify another module's data by bypassing its defined
boundary.

## When it applies

Attendance has more than one business area, so a modular monolith is appropriate
for the documented architecture.

| Situation | Attendance |
|---|---|
| Multiple bounded contexts | Yes |
| One backend deployment | Yes |
| One Spring Boot application | Yes |
| One relational database | Yes |
| Independent microservices required | No |
| Module boundaries required | Yes |

The project does not require separate microservices for these modules. They
remain inside the same application and are deployed together.

## Boundary enforcement

Module boundaries are documented in
[`../02-domain/module-boundaries.md`](../02-domain/module-boundaries.md).

The intended automated enforcement for the Java/Spring backend is documented in
[`./boundary-enforcement.md`](./boundary-enforcement.md).

The main rule is:

> A module may use another module's public API, but it must never depend directly
> on another module's internal implementation.

This keeps Attendance modular without introducing the operational complexity of
multiple independently deployed services.

---

**Related:** [`../02-domain/module-boundaries.md`](../02-domain/module-boundaries.md) · [`./boundary-enforcement.md`](./boundary-enforcement.md) · [`./layered-architecture.md`](./layered-architecture.md)
