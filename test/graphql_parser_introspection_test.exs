defmodule GraphqlParserIntrospectionTest do
  use ExUnit.Case, async: true

  def assert_parse(input_string, expected_output) do
    assert GraphQL.parse(input_string) == expected_output
  end

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
          _type {
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
        _type { ...TypeRef }
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
    """, []
  end
end
