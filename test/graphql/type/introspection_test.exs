defmodule GraphQL.Type.IntrospectionTest do
  use ExUnit.Case, async: true

  import ExUnit.TestHelpers

  alias GraphQL.Schema
  alias GraphQL.Type.Input
  alias GraphQL.Type.Int
  alias GraphQL.Type.NonNull
  alias GraphQL.Type.ObjectType
  alias GraphQL.Type.String

  defmodule EmptySchema do
    def schema do
      Schema.new(%{
        query: %ObjectType{
          name: "QueryRoot",
          fields: %{
            onlyField: %{type: %String{}}
          }
        }
      })
    end
  end

  test "include input types in response to introspection query" do
    type = %ObjectType{
      name: "Thing",
      description: "Things",
      fields: %{
        id: %{type: %Int{}},
        name: %{type: %String{}},
      },
    }

    thing_input_type = %Input{
      name: "ThingInput",
      fields: %{
        name: %{type: %String{}},
      }
    }

    output_type = %ObjectType{
      name: "SaveThingPayload",
      fields: %{
        thing: %{
          type: type,
          resolve: fn(payload, _, _) ->
            payload
          end
        },
      },
    }

    input_type = %Input{
      name: "SaveThingInput",
      fields: %{
        id: %{type: %NonNull{ofType: %Int{}}},
        params: %{type: %NonNull{ofType: thing_input_type}},
      }
    }

    schema = %Schema{
      query: %ObjectType{
        name: "QueryRoot",
        fields: %{onlyField: %{type: %String{}}}
      },
      mutation: %ObjectType{
        name: "Mutation",
        description: "Root object for performing data mutations",
        fields: %{
          save_thing: %{
            type: output_type,
            args: %{
              input: %{
                type: %NonNull{ofType: input_type}
              }
            },
            resolve: fn(data, args, info) ->
              data
            end
          }
        }
      }
    }

    {:ok, result} = execute(schema, GraphQL.Type.Introspection.query)
    assert Enum.find(result.data["__schema"]["types"], fn(type) -> type["name"] == "ThingInput" end)
  end

  test "exposes descriptions on types and fields" do
    schema = Schema.new(%{
      query: %ObjectType{
        name: "QueryRoot",
        fields: %{onlyField: %{type: %String{}}}
      }
    })

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

    {:ok, result} = execute(schema, query)
    assert_data(result, %{
      schemaType: %{
        name: "__Schema",
        description:
          """
          A GraphQL Schema defines the capabilities of a
          GraphQL server. It exposes all available types and
          directives on the server, as well as the entry
          points for query, mutation,
          and subscription operations.
          """ |> GraphQL.Util.Text.normalize,
        fields: [
          %{
            name: "directives",
            description: "A list of all directives supported by this server."
          },
          %{
            name: "mutationType",
            description: "If this server supports mutation, the type that mutation operations will be rooted at."
          },
          %{
            name: "queryType",
            description: "The type that query operations will be rooted at."
          },
          %{
            name: "subscriptionType",
            description: "If this server support subscription, the type that subscription operations will be rooted at.",
          },
          %{
            name: "types",
            description: "A list of all types supported by this server."
          }
        ]
      }
    })
  end
end
