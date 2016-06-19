
defmodule GraphQL.Execution.Executor.BatchResolutionTest do
  use ExUnit.Case, async: true

  import ExUnit.TestHelpers

  alias GraphQL.Schema
  alias GraphQL.Type.ObjectType
  alias GraphQL.Type.String
  alias GraphQL.Type.Int
  alias GraphQL.Execution.Resolvable
  alias GraphQL.Execution.BatchResolvable
  alias GraphQL.Execution.BatchResult
  alias GraphQL.Execution.Patch

  defmodule TestSchema do

    defmodule UsersByIdResolver do
      defstruct id_to_path: %{}

      defimpl Resolvable do
        def resolve(_resolvable, _source, %{id: id}, info) do
          # TODO how do we get the path?
          {:ok, %UsersByIdResolver{id_to_path: %{id => info.path}}}
        end
      end

      defimpl BatchResolvable do
        def group_key(_), do: "users_by_id"

        def batch(b1, b2) do
          %UsersByIdResolver{id_to_path: Map.merge(b1.id_to_path, b2.id_to_path)}
        end

        def resolve(resolver) do
          resolver.id_to_path |> Enum.map(fn({user_id, path}) ->
            %Patch{path: path, value: TestSchema.User.data[user_id]}
          end)
        end

        def batchable?(_), do: true
      end
    end

    defmodule User do

      def data, do: %{0 => %{name: "James"}, 1 => %{name: "Josh"}}

      def type do
        %ObjectType{
          name: "User",
          fields: %{
            id: %{type: %Int{}},
            name: %{type: %String{}}
          }
        }
      end
    end

    def schema do
      %Schema{
        query: %ObjectType{
          name: "Query",
          fields: %{
            user: %{
              type: User,
              args: %{
                id: %{type: %Int{}}
              },
              resolve: %UsersByIdResolver{}
            }
          }
        }
      }
    end
  end

  test "basic query execution" do
    {:ok, result} = execute(TestSchema.schema, """
    {
      user_0: user(id: 0) { name }
      user_1: user(id: 1) { name }
    }
    """)
    assert_data(result, %{
      user_0: %{name: "James"},
      user_1: %{name: "Josh"}
    })
  end

end
