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
         name: %{kind: :Name, loc: %{start: 0},
           value: "IntrospectionQuery"}, operation: :query,
         selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
           selections: [%{kind: :Field, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0}, value: "__schema"},
              selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
                selections: [%{kind: :Field, loc: %{start: 0},
                   name: %{kind: :Name, loc: %{start: 0},
                     value: "queryType"},
                   selectionSet: %{kind: :SelectionSet,
                     loc: %{start: 0},
                     selections: [%{kind: :Field, loc: %{start: 0},
                        name: %{kind: :Name, loc: %{start: 0},
                          value: "name"}}]}},
                 %{kind: :Field, loc: %{start: 0},
                   name: %{kind: :Name, loc: %{start: 0},
                     value: "mutationType"},
                   selectionSet: %{kind: :SelectionSet,
                     loc: %{start: 0},
                     selections: [%{kind: :Field, loc: %{start: 0},
                        name: %{kind: :Name, loc: %{start: 0},
                          value: "name"}}]}},
                 %{kind: :Field, loc: %{start: 0},
                   name: %{kind: :Name, loc: %{start: 0},
                     value: "types"},
                   selectionSet: %{kind: :SelectionSet,
                     loc: %{start: 0},
                     selections: [%{kind: :FragmentSpread,
                        loc: %{start: 0},
                        name: %{kind: :Name, loc: %{start: 0},
                          value: "FullType"}}]}},
                 %{kind: :Field, loc: %{start: 0},
                   name: %{kind: :Name, loc: %{start: 0},
                     value: "directives"},
                   selectionSet: %{kind: :SelectionSet,
                     loc: %{start: 0},
                     selections: [%{kind: :Field, loc: %{start: 0},
                        name: %{kind: :Name, loc: %{start: 0},
                          value: "name"}},
                      %{kind: :Field, loc: %{start: 0},
                        name: %{kind: :Name, loc: %{start: 0},
                          value: "description"}},
                      %{kind: :Field, loc: %{start: 0},
                        name: %{kind: :Name, loc: %{start: 0},
                          value: "args"},
                        selectionSet: %{kind: :SelectionSet,
                          loc: %{start: 0},
                          selections: [%{kind: :FragmentSpread,
                             loc: %{start: 0},
                             name: %{kind: :Name, loc: %{start: 0},
                               value: "InputValue"}}]}},
                      %{kind: :Field, loc: %{start: 0},
                        name: %{kind: :Name, loc: %{start: 0},
                          value: "onOperation"}},
                      %{kind: :Field, loc: %{start: 0},
                        name: %{kind: :Name, loc: %{start: 0},
                          value: "onFragment"}},
                      %{kind: :Field, loc: %{start: 0},
                        name: %{kind: :Name, loc: %{start: 0},
                          value: "onField"}}]}}]}}]}},
       %{kind: :FragmentDefinition, loc: %{start: 0},
         name: %{kind: :Name, loc: %{start: 0}, value: "FullType"},
         selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
           selections: [%{kind: :Field, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0}, value: "kind"}},
            %{kind: :Field, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0}, value: "name"}},
            %{kind: :Field, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0},
                value: "description"}},
            %{kind: :Field, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0}, value: "fields"},
              selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
                selections: [%{kind: :Field, loc: %{start: 0},
                   name: %{kind: :Name, loc: %{start: 0},
                     value: "name"}},
                 %{kind: :Field, loc: %{start: 0},
                   name: %{kind: :Name, loc: %{start: 0},
                     value: "description"}},
                 %{kind: :Field, loc: %{start: 0},
                   name: %{kind: :Name, loc: %{start: 0},
                     value: "args"},
                   selectionSet: %{kind: :SelectionSet,
                     loc: %{start: 0},
                     selections: [%{kind: :FragmentSpread,
                        loc: %{start: 0},
                        name: %{kind: :Name, loc: %{start: 0},
                          value: "InputValue"}}]}},
                 %{kind: :Field, loc: %{start: 0},
                   name: %{kind: :Name, loc: %{start: 0},
                     value: "type"},
                   selectionSet: %{kind: :SelectionSet,
                     loc: %{start: 0},
                     selections: [%{kind: :FragmentSpread,
                        loc: %{start: 0},
                        name: %{kind: :Name, loc: %{start: 0},
                          value: "TypeRef"}}]}},
                 %{kind: :Field, loc: %{start: 0},
                   name: %{kind: :Name, loc: %{start: 0},
                     value: "isDeprecated"}},
                 %{kind: :Field, loc: %{start: 0},
                   name: %{kind: :Name, loc: %{start: 0},
                     value: "deprecationReason"}}]}},
            %{kind: :Field, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0},
                value: "inputFields"},
              selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
                selections: [%{kind: :FragmentSpread, loc: %{start: 0},
                   name: %{kind: :Name, loc: %{start: 0},
                     value: "InputValue"}}]}},
            %{kind: :Field, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0},
                value: "interfaces"},
              selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
                selections: [%{kind: :FragmentSpread, loc: %{start: 0},
                   name: %{kind: :Name, loc: %{start: 0},
                     value: "TypeRef"}}]}},
            %{kind: :Field, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0},
                value: "enumValues"},
              selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
                selections: [%{kind: :Field, loc: %{start: 0},
                   name: %{kind: :Name, loc: %{start: 0},
                     value: "name"}},
                 %{kind: :Field, loc: %{start: 0},
                   name: %{kind: :Name, loc: %{start: 0},
                     value: "description"}},
                 %{kind: :Field, loc: %{start: 0},
                   name: %{kind: :Name, loc: %{start: 0},
                     value: "isDeprecated"}},
                 %{kind: :Field, loc: %{start: 0},
                   name: %{kind: :Name, loc: %{start: 0},
                     value: "deprecationReason"}}]}},
            %{kind: :Field, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0},
                value: "possibleTypes"},
              selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
                selections: [%{kind: :FragmentSpread, loc: %{start: 0},
                   name: %{kind: :Name, loc: %{start: 0},
                     value: "TypeRef"}}]}}]},
         typeCondition: %{kind: :NamedType, loc: %{start: 0},
           name: %{kind: :Name, loc: %{start: 0}, value: "__Type"}}},
       %{kind: :FragmentDefinition, loc: %{start: 0},
         name: %{kind: :Name, loc: %{start: 0}, value: "InputValue"},
         selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
           selections: [%{kind: :Field, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0}, value: "name"}},
            %{kind: :Field, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0},
                value: "description"}},
            %{kind: :Field, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0}, value: "type"},
              selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
                selections: [%{kind: :FragmentSpread, loc: %{start: 0},
                   name: %{kind: :Name, loc: %{start: 0},
                     value: "TypeRef"}}]}},
            %{kind: :Field, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0},
                value: "defaultValue"}}]},
         typeCondition: %{kind: :NamedType, loc: %{start: 0},
           name: %{kind: :Name, loc: %{start: 0},
             value: "__InputValue"}}},
       %{kind: :FragmentDefinition, loc: %{start: 0},
         name: %{kind: :Name, loc: %{start: 0}, value: "TypeRef"},
         selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
           selections: [%{kind: :Field, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0}, value: "kind"}},
            %{kind: :Field, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0}, value: "name"}},
            %{kind: :Field, loc: %{start: 0},
              name: %{kind: :Name, loc: %{start: 0}, value: "ofType"},
              selectionSet: %{kind: :SelectionSet, loc: %{start: 0},
                selections: [%{kind: :Field, loc: %{start: 0},
                   name: %{kind: :Name, loc: %{start: 0},
                     value: "kind"}},
                 %{kind: :Field, loc: %{start: 0},
                   name: %{kind: :Name, loc: %{start: 0},
                     value: "name"}},
                 %{kind: :Field, loc: %{start: 0},
                   name: %{kind: :Name, loc: %{start: 0},
                     value: "ofType"},
                   selectionSet: %{kind: :SelectionSet,
                     loc: %{start: 0},
                     selections: [%{kind: :Field, loc: %{start: 0},
                        name: %{kind: :Name, loc: %{start: 0},
                          value: "kind"}},
                      %{kind: :Field, loc: %{start: 0},
                        name: %{kind: :Name, loc: %{start: 0},
                          value: "name"}},
                      %{kind: :Field, loc: %{start: 0},
                        name: %{kind: :Name, loc: %{start: 0},
                          value: "ofType"},
                        selectionSet: %{kind: :SelectionSet,
                          loc: %{start: 0},
                          selections: [%{kind: :Field, loc: %{start: 0},
                             name: %{kind: :Name, loc: %{start: 0},
                               value: "kind"}},
                           %{kind: :Field, loc: %{start: 0},
                             name: %{kind: :Name, loc: %{start: 0},
                               value: "name"}}]}}]}}]}}]},
         typeCondition: %{kind: :NamedType, loc: %{start: 0},
           name: %{kind: :Name, loc: %{start: 0}, value: "__Type"}}}],
      kind: :Document, loc: %{start: 0}}
  end
end
