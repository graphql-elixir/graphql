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
    assert_execute({query, StarWars.Schema.schema}, %{})
  end
end
