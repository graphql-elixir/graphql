
defmodule GraphQL.Execution.Executor.MutationsTest do
  use ExUnit.Case, async: true

  import ExUnit.TestHelpers

  alias GraphQL
  alias GraphQL.Schema
  alias GraphQL.Type.ObjectType
  alias GraphQL.Type.Int

  defmodule NumberHolder do
    def type do
      %ObjectType{
        name: "NumberHolder",
        fields: %{
          theNumber: %{type: %Int{}}
        }
      }
    end
  end

  defmodule TestSchema do
    def schema do
      %Schema{
        query: %ObjectType{
          name: "Query",
          fields: %{
            theNumber: %{type: NumberHolder.type}
          }
        },
        mutation: %ObjectType{
          name: "Mutation",
          fields: %{
            changeTheNumber: %{
              type: NumberHolder.type,
              args: %{ newNumber: %{ type: %Int{} }},
              resolve: fn(source, %{ newNumber: newNumber }, _) ->
                Map.put(source, :theNumber, newNumber)
              end
            },
            failToChangeTheNumber: %{
              type: NumberHolder.type,
              args: %{ newNumber: %{ type: %Int{} }},
              resolve: fn(_, %{ newNumber: _ }, _) ->
                raise "Cannot change the number"
              end
            }
          }
        }
      }
    end
  end

  test "evaluates mutations serially" do
    doc = """
      mutation M {
        first: changeTheNumber(newNumber: 1) {
          theNumber
        },
        second: changeTheNumber(newNumber: 2) {
          theNumber
        },
        third: changeTheNumber(newNumber: 3) {
          theNumber
        }
      }
    """

    assert_execute {doc, TestSchema.schema}, %{
      first: %{theNumber: 1},
      second: %{theNumber: 2},
      third: %{theNumber: 3},
    }
  end

  test "evaluates mutations correctly in the presense of a failed mutation" do
    doc = """
      mutation M {
        first: changeTheNumber(newNumber: 1) {
          theNumber
        },
        second: failToChangeTheNumber(newNumber: 2) {
          theNumber
        }
        third: changeTheNumber(newNumber: 3) {
          theNumber
        }
      }
    """

    assert_execute {doc, TestSchema.schema}, %{
      first: %{
        theNumber: 1
      },
      second: nil,
      third: %{
        theNumber: 3
      }
    }

    assert_execute_error {doc, TestSchema.schema}, [
      %{"message" => "Cannot change the number"}
    ]
  end
end

