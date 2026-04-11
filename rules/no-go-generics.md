# No Go Generics

## Rule
Do NOT use Go generics (type parameters) when implementing code in any Layer 8 project. Use interfaces, concrete types, or `interface{}` / `any` instead.

## What NOT to Do
```go
// WRONG - generic function
func Filter[T any](items []T, fn func(T) bool) []T { ... }

// WRONG - generic type
type Cache[K comparable, V any] struct { ... }
```

## What to Do Instead
```go
// CORRECT - use interfaces or concrete types
func Filter(items []interface{}, fn func(interface{}) bool) []interface{} { ... }

// CORRECT - use concrete types when the type is known
func FilterEmployees(items []*Employee, fn func(*Employee) bool) []*Employee { ... }
```
