# <div align="center"> API & Query Language

>An API is a language.  
Protocols are merely the alphabet.

Because APIs ***are languages***, inconsistency is not cosmetic; it directly increases cognitive load, 
fragmentation, and long-term system complexity.

Yet in most systems, every service invents its own language,
even though they all use the same alphabet.

- Different verbs.  
- Different rules.  
- Different meanings for the same concepts.

This fragmentation is not accidental.
It is the result of treating APIs as implementation details
instead of shared communication contracts.

Attempts to normalize APIs usually focus on syntax. They standardize the alphabet, 
while allowing every service to **keep inventing** its own language.

> ***This is the root of much of the complexity in service development.***

Layer 8 takes a different approach.

Instead of standardizing how services speak, it standardizes what can be expressed.

This chapter describes **service-to-service** APIs within the Layer 8 platform; 
how these APIs are exposed over a web interface is covered separately in the **Web Server chapter**.

---
## Model as API

As established in Chapter 7, a Layer 8 service is organized around a **Prime Object**.
The service exposes a facade that follows REST-style semantics, 
making it natural to use a Prime Object instance as the input for:

POST, PUT, PATCH, DELETE, and GET.

For GET operations, a single Prime Object instance acts as a filter. 
The service returns all items that match the attributes provided in the input instance.

This works well for individual interactions. However, real systems do not operate one item at a time.

**They operate at scale.** Scale requires bulk operations.

In Layer 8, the input and output of service API calls are **Elements** (introduced in Chapter 8).

Elements reduce API surface area by replacing many specialized request and response types with 
a single, uniform container. Instead of defining separate service operations, payload schemas, 
and pagination contracts, services expose a small, fixed set of interactions that all accept 
and return **Elements**.

Because Elements can represent single items, collections, partial projections, and metadata 
within the same structure, new capabilities are added by expressing intent in the model and query
language rather than by expanding the service API itself.

### Example: a service API that disappears entirely  
In a conventional microservice system, a consuming service typically requires dedicated 
operations such as ListEmployees, SearchEmployees, or GetEmployeePage.

In Layer 8, those operations do not exist. The caller issues:

>Request(ServiceName, ServiceArea, Get, payload, timeout) -> IElements

If payload is a valid L8Query string, Elements is instantiated as that query.
Otherwise, Elements is instantiated from the provided model data,
aligning itself to a single element or multiple elements.

The response is always IElements, with metadata describing the scope of the result
(for example, which page was returned and how many elements exist in total).

The capability lives in the model and query language, not in new service-specific APIs.

---
## Prime Object Lists

Layer 8 addresses large result sets by enforcing a simple, consistent definition for **Prime Object**
Lists.

For a given Prime Object:

```
message Employee {
}
```

the corresponding list type must be defined as:

```
message EmployeeList {
  repeated Employee list = 1;
  l8api.L8MetaData metadata = 2;
}
```

The list field contains the requested page of results. The page size and page selection 
are defined by the L8Query.

The **metadata** field is populated automatically by the Layer 8 infrastructure.
It can be extended through observer functions to compute and expose additional information 
required by user interfaces, such as total counts or aggregate values.

By treating the model itself as the API, Layer 8 removes the need for custom service operations, 
ad-hoc paging logic, and service-specific response formats.

**The model defines the contract. The platform handles the mechanics.**

---
## Layer 8 Query Language

There are existing query languages for graph and tree-based models. While powerful, 
they are often far more complex than what Layer 8 requires.

During the design of the Introspector (Chapter 9), an important realization emerged:
because Layer 8 already **understands** the model structure at runtime,
**querying does not require a new or complex language.**

This is the same foundation as the model-agnostic runtime. Services do not need 
compile-time knowledge of concrete types to interpret intent. The platform resolves 
the root model type, traverses nested structure, and interprets PropertyId paths using 
runtime introspection, so query semantics remain stable even as models evolve.

Instead, Layer 8 uses a simple, familiar, SQL-inspired syntax adapted to operate 
directly on nested models.

This led to the creation of the **Layer 8 Query Language.**

### Query Structure

A query always starts with the keyword `select`, followed by either:

- a list of attributes, or
- `*` to select the full model instance.

Attributes are referenced using **PropertyId** notation, introduced in Chapter 9.

The `from` clause specifies the root model type. Unlike traditional SQL, there is no 
table name. There is exactly **one root**, which represents the model itself.

The `where` clause defines filtering criteria using the form:

`PropertyID {operator} value`

Paging is handled using:

- `limit` to define page size
- `page` to select the page number

### Example Model

```
message Employee {
  string id = 1;
  string name = 2;
  repeated Addr addresses = 3;
}

message Addr {
  string line1 = 1;
  string line2 = 2;
  int32 zip = 3;
}
```

### Example Queries

> select * from Employee

<- retrieve all full Employee model instances.

> select id,name from Employee

<- retrieve all Employee instances with only id and name populated.

> select * from Employee where id='layer8'

<- retrieve the full Employee model with id equal to 'layer8'.

> select id,name from Employee where addresses.zip=95124

<- retrieve all Employees with at least one address having zip 95124.

> select id,name from Employee where addresses<5{1}>.zip=95124

<- retrieve all Employees whose second address has zip 95124.

> select * from Employee limit 50 page 3

<- retrieve page 3 with a page size of 50 (items 150-199, zero-based).

The Layer 8 Query Language is supported by both:

- the Layer 8 Distributed Cache, and
- the Layer 8 ORM (covered in Chapter 12).

A complete language reference and specification is available at:  
https://github.com/saichler/l8ql

By aligning query semantics directly with the model, Layer 8 eliminates 
the need for:

- table abstractions,
- object-relational impedance layers,
- and service-specific query operations.

The model defines what can be queried.  
The query language expresses intent.  
The platform executes it.

Note: How Layer 8 exposes APIs through a web interface is covered in the **Web Server chapter.**