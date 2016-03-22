defmodule GraphQL.Type.IntrospectionTest do
  use ExUnit.Case, async: true

  import ExUnit.TestHelpers

  alias GraphQL.Schema
  alias GraphQL.Type.Object
  alias GraphQL.Type.String

  defmodule EmptySchema do
    def schema do
      %Schema{
        query: %Object{
          name: "QueryRoot",
          fields: %{
            onlyField: %{type: %String{}}
          }
        }
      }
    end
  end

  test "basic query introspection" do
    # assert_execute
    #   {GraphQL.Type.Introspection.query, EmptySchema.schema},
  end

  @tag :skip # order matters for this... ... hm.
  test "exposes descriptions on types and fields" do
    schema = %Schema{
      query: %Object{
        name: "QueryRoot",
        fields: %{onlyField: %{type: %String{}}}
      }
    }

    query = """
    {
      schemaType: __type(name: "__Schema") {
        name
        description
        fields {
          name,
          description
        }
      }
    }
    """

    assert_execute {query, schema}, %{
      schemaType: %{
        name: "__Schema",
        description:
          """
          A GraphQL Schema defines the capabilities of a
          GraphQL server. It exposes all available types and
          directives on the server, as well as the entry
          points for query, mutation,
          and subscription operations.
          """,
        fields: [
          %{
            name: "types",
            description: "A list of all types supported by this server."
          },
          %{
            name: "queryType",
            description: "The type that query operations will be rooted at."
          },
          %{
            name: "mutationType",
            description: "If this server supports mutation, the type that mutation operations will be rooted at."
          },
          %{
            name: "subscriptionType",
            description: "If this server support subscription, the type that subscription operations will be rooted at.",
          },
          %{
            name: "directives",
            description: "A list of all directives supported by this server."
          }
        ]
      }
    }
  end
end
