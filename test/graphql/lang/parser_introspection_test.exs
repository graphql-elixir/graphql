defmodule GraphQL.Lang.Parser.IntrospectionTest do
  use ExUnit.Case, async: true

  import ExUnit.TestHelpers

  test "Introspection Query" do
    assert_parse """
      # The introspection query to end all introspection queries, copied from
      # https://github.com/graphql/graphql-js/blob/master/src/utilities/introspectionQuery.js

      query IntrospectionQuery {
        __schema {
          queryType { name }
          mutationType { name }
          types {
            ...FullType
          }
          directives {
            name
            description
            args {
              ...InputValue
            }
            onOperation
            onFragment
            onField
          }
        }
      }
      fragment FullType on __Type {
        kind
        name
        description
        fields {
          name
          description
          args {
            ...InputValue
          }
          type {
            ...TypeRef
          }
          isDeprecated
          deprecationReason
        }
        inputFields {
          ...InputValue
        }
        interfaces {
          ...TypeRef
        }
        enumValues {
          name
          description
          isDeprecated
          deprecationReason
        }
        possibleTypes {
          ...TypeRef
        }
      }
      fragment InputValue on __InputValue {
        name
        description
        type { ...TypeRef }
        defaultValue
      }
      fragment TypeRef on __Type {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
            }
          }
        }
      }
    """,
    %{definitions: [%{kind: :OperationDefinition, loc: %{start: 0},
       name: "IntrospectionQuery", operation: :query,
       selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
         selections: [%{kind: :Field, loc: %{start: 0}, name: "__schema",
            selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
              selections: [%{kind: :Field, loc: %{start: 0}, name: "queryType",
                 selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
                   selections: [%{kind: :Field, loc: %{start: 0},
                      name: "name"}]}},
               %{kind: :Field, loc: %{start: 0}, name: "mutationType",
                 selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
                   selections: [%{kind: :Field, loc: %{start: 0},
                      name: "name"}]}},
               %{kind: :Field, loc: %{start: 0}, name: "types",
                 selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
                   selections: [%{kind: :FragmentSpread, loc: %{start: 0},
                      name: "FullType"}]}},
               %{kind: :Field, loc: %{start: 0}, name: "directives",
                 selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
                   selections: [%{kind: :Field, loc: %{start: 0}, name: "name"},
                    %{kind: :Field, loc: %{start: 0}, name: "description"},
                    %{kind: :Field, loc: %{start: 0}, name: "args",
                      selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
                        selections: [%{kind: :FragmentSpread, loc: %{start: 0},
                           name: "InputValue"}]}},
                    %{kind: :Field, loc: %{start: 0}, name: "onOperation"},
                    %{kind: :Field, loc: %{start: 0}, name: "onFragment"},
                    %{kind: :Field, loc: %{start: 0}, name: "onField"}]}}]}}]}},
     %{kind: :FragmentDefinition, loc: %{start: 0}, name: "FullType",
       selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
         selections: [%{kind: :Field, loc: %{start: 0}, name: "kind"},
          %{kind: :Field, loc: %{start: 0}, name: "name"},
          %{kind: :Field, loc: %{start: 0}, name: "description"},
          %{kind: :Field, loc: %{start: 0}, name: "fields",
            selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
              selections: [%{kind: :Field, loc: %{start: 0}, name: "name"},
               %{kind: :Field, loc: %{start: 0}, name: "description"},
               %{kind: :Field, loc: %{start: 0}, name: "args",
                 selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
                   selections: [%{kind: :FragmentSpread, loc: %{start: 0},
                      name: "InputValue"}]}},
               %{kind: :Field, loc: %{start: 0}, name: "type",
                 selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
                   selections: [%{kind: :FragmentSpread, loc: %{start: 0},
                      name: "TypeRef"}]}},
               %{kind: :Field, loc: %{start: 0}, name: "isDeprecated"},
               %{kind: :Field, loc: %{start: 0}, name: "deprecationReason"}]}},
          %{kind: :Field, loc: %{start: 0}, name: "inputFields",
            selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
              selections: [%{kind: :FragmentSpread, loc: %{start: 0},
                 name: "InputValue"}]}},
          %{kind: :Field, loc: %{start: 0}, name: "interfaces",
            selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
              selections: [%{kind: :FragmentSpread, loc: %{start: 0},
                 name: "TypeRef"}]}},
          %{kind: :Field, loc: %{start: 0}, name: "enumValues",
            selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
              selections: [%{kind: :Field, loc: %{start: 0}, name: "name"},
               %{kind: :Field, loc: %{start: 0}, name: "description"},
               %{kind: :Field, loc: %{start: 0}, name: "isDeprecated"},
               %{kind: :Field, loc: %{start: 0}, name: "deprecationReason"}]}},
          %{kind: :Field, loc: %{start: 0}, name: "possibleTypes",
            selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
              selections: [%{kind: :FragmentSpread, loc: %{start: 0},
                 name: "TypeRef"}]}}]},
       typeCondition: %{kind: :NamedType, loc: %{start: 0}, name: "__Type"}},
     %{kind: :FragmentDefinition, loc: %{start: 0}, name: "InputValue",
       selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
         selections: [%{kind: :Field, loc: %{start: 0}, name: "name"},
          %{kind: :Field, loc: %{start: 0}, name: "description"},
          %{kind: :Field, loc: %{start: 0}, name: "type",
            selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
              selections: [%{kind: :FragmentSpread, loc: %{start: 0},
                 name: "TypeRef"}]}},
          %{kind: :Field, loc: %{start: 0}, name: "defaultValue"}]},
       typeCondition: %{kind: :NamedType, loc: %{start: 0},
         name: "__InputValue"}},
     %{kind: :FragmentDefinition, loc: %{start: 0}, name: "TypeRef",
       selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
         selections: [%{kind: :Field, loc: %{start: 0}, name: "kind"},
          %{kind: :Field, loc: %{start: 0}, name: "name"},
          %{kind: :Field, loc: %{start: 0}, name: "ofType",
            selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
              selections: [%{kind: :Field, loc: %{start: 0}, name: "kind"},
               %{kind: :Field, loc: %{start: 0}, name: "name"},
               %{kind: :Field, loc: %{start: 0}, name: "ofType",
                 selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
                   selections: [%{kind: :Field, loc: %{start: 0}, name: "kind"},
                    %{kind: :Field, loc: %{start: 0}, name: "name"},
                    %{kind: :Field, loc: %{start: 0}, name: "ofType",
                      selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
                        selections: [%{kind: :Field, loc: %{start: 0},
                           name: "kind"},
                         %{kind: :Field, loc: %{start: 0},
                           name: "name"}]}}]}}]}}]},
       typeCondition: %{kind: :NamedType, loc: %{start: 0}, name: "__Type"}}],
    kind: :Document, loc: %{start: 0}}
  end
end
