# <div align="center"> Object Relation Mapping

Persisting object models into relational databases has always been hard.
Object Relational Mapping (ORM) was introduced as a solution.

The idea sounds simple:  
annotate your model with relational hints, and let an ORM translate objects to tables and 
records, and back again.

On paper, this looks like progress.  
In practice, it creates new problems.

---
## Explicit ORM Failure Modes This Replaces

Traditional ORMs tend to fail in predictable ways:

- N+1 query explosions caused by implicit lazy loading
- Unbounded object graph hydration
- Unpredictable performance due to implicit joins
- Schema leakage into domain models via annotations
- Vendor and dialect coupling
- Fragile migrations and schema drift
- Cascade and orphan side effects
- Transaction boundary ambiguity
- Impedance-mismatch driven model distortion

Layer 8 eliminates these failure modes by removing implicit, instance-driven persistence
and replacing it with introspection and explicit interfaces.

First, the persistence layer becomes tightly coupled to relational databases,
often to a specific vendor or dialect.

Second, the complexity does not disappear. It moves.

Instead of maintaining database schemas, teams now maintain annotation-heavy models.
As models grow larger and more deeply nested, this annotation burden becomes significant.

The model stops representing the domain. It starts representing the database.

Layer 8 takes a different approach.

To achieve this, Layer 8 decomposes the traditional ORM concept into three distinct layers,
connected only through explicit interfaces and owned boundaries:

**Service**  
Exposes persistence as a storage-agnostic contract (using the standard Layer 8 service interface),
while keeping consuming services unaware of storage mechanics.

**Convert**  
Owned by the persistence adapter, Convert projects model instances to and from relational 
data using introspection, without embedding database concerns into the model.

**Persist**  
Also owned by the persistence adapter, Persist handles durable storage and retrieval of relational 
data, isolated from both domain semantics and model authorship.

By separating Service, Convert, and Persist, Layer 8 eliminates tight coupling, 
prevents schema leakage into the model, and allows each layer to evolve independently.

Persistence becomes composable, replaceable, and intentional.

## Ownership Boundaries: Services vs Persistence

Layer 8 enforces a strict separation between domain ownership and storage ownership.

A consuming service has no persistence or storage awareness. It does not know tables, schemas, 
indexes, queries, serialization formats, or database dialects.

A service owns:
- the domain lifecycle of a Prime Object
- validation and invariants
- concurrency ownership
- domain behavior

The persistence adapter owns all storage representation and durability, including:
- Convert: projecting an introspected model into relational form and reconstructing it on read
- Persist: executing durable read and write operations against the selected backend

This separation keeps services portable while allowing persistence plugins to evolve, 
optimize, or swap backends without leaking schema concerns into domain logic.

---
## Layer 8 Relational Model

The implementation of Chapters 9 and 11 reveals an important outcome:
Layer 8 already has enough information to translate any model instance
into relational data without requiring additional annotations or hints.

No ORM-specific metadata is needed.

The rule of thumb is simple:  
- Every struct or class in the model maps to a Logical Table.
- Every model instance maps to one or more Logical Rows.
- Each Logical Row is uniquely identified by a PropertyId.

This mapping is derived entirely from the introspected model structure. 
To formalize this, Layer 8 introduces the L8RelationData model.

L8RelationData represents relational state as a logical abstraction, independent of any 
physical database implementation.

*It consists of*:

- A map from struct name to Logical Table.
- Each Logical Table contains a map from PropertyId to Logical Row.
- Each Logical Row contains a map from field name to field value.

*In other words*:

- Tables are logical, not physical.
- Rows are identified by model paths, not primary keys.
- Fields retain their original semantic meaning.

This relational representation is derived, not designed. It emerges naturally from the model and its structure.

By treating relational data as a projection of the model, Layer 8 avoids schema annotations, 
mapping rules, and database-specific assumptions.

The model remains pure. The relational view is generated. 
Persistence adapts to the model.

---
## Service

The Layer 8 ORM Service encapsulates the interaction between the Convert and Persist components
and presents them with the same look and feel as the Distributed Cache component.

From the perspective of a consuming service, persistence is invisible. 
The service remains completely agnostic to:
- how data is converted,
- how it is stored,
- and how queries are executed.

Interaction with the ORM Service uses the standard Layer 8 service interface:
POST, PUT, PATCH, DELETE, and GET, as described in Chapter 11.

### Write Path

For write operations, the Service layer:
- converts model instances into relational data using the Convert interface,
- passes the resulting relational data to the Persist layer for storage.

### Read Path

For query operations, the Service layer:
- forwards the L8Query directly to the Persist layer,
- receives relational data as a result,
- passes that data through the Convert interface,
- and returns model instances to the caller.

At no point does the consuming service interact with relational structures, schemas, 
or database-specific details.

The Service layer acts as a facade. It enforces the service contract, coordinates conversion 
and persistence, and preserves the illusion of working with an in-memory, model-native system.

**Persistence becomes a service, not a concern.**

---
## Convert

The Convert layer performs a mechanical, deterministic operation. There is no hidden complexity 
and no domain logic.

*It takes*:
- model instances and converts them into relational data, or
- relational data and converts it back into model instances.

All conversions are driven entirely by the Introspector blueprint and the Property mechanism described 
in Chapter 9. No model-specific rules are embedded. No database-specific assumptions are made.

Conversion is structural, not semantic. It preserves shape and values, not business meaning.

By keeping conversion purely mechanical, Layer 8 ensures that persistence logic remains 
predictable, testable, and replaceable.

The Convert layer does one thing: **translate representations. Nothing more.**

---
## Persist

Persisting relational data is intentionally straightforward.

Relational data can be stored in:
- relational database tables,
- files,
- NoSql, 
- or any other durable storage mechanism.

Layer 8 avoids complex annotations and mapping rules. Instead, it relies on two universal columns 
added to every relational record:
- ParentPropertyId
- PropertyId

With these two identifiers, the full object graph can be reconstructed deterministically. 
No additional schema hints or model annotations are required. The Persist interface enforces 
**L8Query** as the input for read operations. This abstracts away all implementation details.

Each persistence plugin is responsible for:
- translating L8Query into an optimized query for its underlying storage system,
- executing that query efficiently,
- and returning relational data in a standard format.

The Persist layer knows nothing about:
- model semantics,
- service behavior,
- or business logic.

**It focuses solely on durable storage and retrieval.**

By isolating persistence behind a strict interface, Layer 8 allows storage engines to be swapped, 
optimized, or replaced without impacting services, models, or APIs.

**Persistence becomes pluggable. The contract remains stable. The system evolves safely.**

---
## Schema Evolution Without Service Coordination

Layer 8 supports schema evolution without requiring service-to-service coordination, synchronized deployments, 
or schema awareness inside services.

Model evolution commonly falls into two categories:

Trivial changes
- adding or removing attributes

Structural changes
- renaming or reshaping fields or sub-models
- splitting or merging structures

---
### Trivial evolution

For additive or subtractive attribute changes, the persistence adapter can detect model shape drift
through introspection at initialization and apply safe, automatic adjustments to its storage representation.

Existing services continue operating unchanged, and the system avoids silent overwrites of newly added fields.

### Structural evolution

Some changes cannot be inferred safely and require explicit intent to avoid data loss or semantic corruption.

When structural drift is detected:
- the persistence adapter determines that the change is non-trivial
- the domain service supplies migration intent through a persistence-provided interface
- the persistence adapter applies that intent consistently and durably

If no intent is supplied, the system may continue operating conservatively,
prioritizing data safety over aggressive transformation.

---
## A Word On Plugin Implementation

Creating tables, indexes, and persisting relational data is generally straightforward.

Translating an L8Query into an optimized, storage-specific query is not.

For example, converting L8Query into efficient PostgreSQL SQL requires query planning, 
index awareness, and execution strategy decisions. These concerns are inherently storage-specific.

Layer 8 provides components, assisted by AI, to handle this translation. However, 
a small portion of this logic is necessarily database-specific.

For that reason, these components are intentionally not part of the core ORM abstraction.

**Instead, they are provided as reference implementations.**

They can be forked, adapted, and extended to create persistence plugins for other storage 
engines with minimal effort.

The boundary is deliberate:

- Layer 8 defines the contract.
- Plugins handle optimization.

**Storage-specific intelligence remains isolated.**

This keeps the ORM portable, while still allowing high-performance, 
storage-aware implementations.

---
## Reinforcing Rule #5: Interface, Not Instance

This chapter relies on Rule #5: Interface, not Instance.

Services in Layer 8 never interact with persistence through live objects, sessions,
repositories, or database-backed entities. Instead, services express intent through 
interfaces, and persistence plugins execute that intent against concrete storage instances.

This separation is what makes the ORM replacement predictable:
it prevents hidden side effects, keeps storage lifetimes out of domain logic,
and allows persistence representation and implementation to evolve independently.
