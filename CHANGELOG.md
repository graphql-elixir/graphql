# Changelog

## 0.3.2 (2016-06-09)

* Enhancements
  * Future support for deferred resolvers
  * GraphQL IDL compiler

* Bugfixes
  * Validate operation name matches an operation
  * Resolve no longer fails when it cannot find a matching function
  * Fix 1.3 warnings


## 0.3.1 (2016-06-09)

* Bugfixes
  * Fix introspection to include Input types when input types are arguments
    to fields.


## 0.3.0 (2016-05-29)

* Enhancements
  * Directive support (@skip and @include)
  * Validations now run on queries
    * Rule: Fields on correct type
    * Rule: No fragment cycles
    * Rule: Validate mandatory arguments
    * Rule: Unique operation names

* Bugfixes
  * Allow default values to get assigned correctly when a query defines
    an enum variable with a default
  * Query can take an optional Enum argument and correctly fall back if
    that value is not specified

* Note: the `execute/5` signature will be changed to the `execute_with_opts/3`
  in a future version


## 0.2.0 (2016-03-19)

* Enhancements
  * Interface, Union and Input type support
  * Types can be referenced in schemas using modules or atoms
  * Require Elixir 1.2 and above

* Bugfixes
  * Resolve now accepts a map with string keys
  * Duplicate field definitions handled correctly (required for Relay support)
