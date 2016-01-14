Code.require_file "../support/star_wars/data.exs", __DIR__
Code.require_file "../support/star_wars/schema.exs", __DIR__

defmodule GraphQL.StarWars.IntrospectionTest do
  use ExUnit.Case, async: true
  import ExUnit.TestHelpers

  test "Allows querying the schema for types" do
    query = """
      query IntrospectionTypeQuery {
          __schema {
            types {
              name
            }
          }
        }
    """
    wanted = %{
      __schema:
        %{types: [
          %{name: "Boolean"},
          %{name: "Character"},
          %{name: "Droid"},
          %{name: "Episode"},
          %{name: "Human"},
          %{name: "Query"},
          %{name: "String"},
          %{name: "__Directive"},
          %{name: "__EnumValue"},
          %{name: "__Field"},
          %{name: "__InputValue"},
          %{name: "__Schema"},
          %{name: "__Type"},
          %{name: "__TypeKind"}
        ]
      }
    }
    assert_execute {query, StarWars.Schema.schema}, wanted
  end

  test "Allows querying the schema for query type" do
    query = """
     query IntrospectionQueryTypeQuery {
      __schema {
        queryType {
          name
        }
      }
    }
    """
    assert_execute {query, StarWars.Schema.schema}, %{__schema: %{queryType: %{name: "Query"}}}
  end

  test "Allows querying the schema for a specific type" do
    query = """
      query IntrospectionDroidTypeQuery {
        __type(name: "Droid") {
          name
        }
      }
    """
    assert_execute {query, StarWars.Schema.schema}, %{__type: %{name: "Droid"}}
  end

  test "Allows querying the schema for an object kind" do
    query = """
      query IntrospectionDroidKindQuery {
        __type(name: "Droid") {
          name
          kind
        }
      }
    """
    assert_execute {query, StarWars.Schema.schema}, %{__type: %{name: "Droid", kind: "OBJECT"}}
  end
end
