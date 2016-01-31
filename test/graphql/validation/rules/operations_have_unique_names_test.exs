defmodule GraphQL.Validation.Rules.OperationsHaveUniqueNamesTest do
  use ExUnit.Case, async: true

  import ExUnit.TestHelpers

  alias GraphQL.Schema
  alias GraphQL.Type.ObjectType
  alias GraphQL.Type.List
  alias GraphQL.Type.ID
  alias GraphQL.Type.String
  alias GraphQL.Type.Int

  defmodule TestSchema do
    def schema do
      %Schema{
        query: %ObjectType{
          name: "dog",
          fields: %{
            owner: %{
              type: %ObjectType{},
              fields: %{
                name: %{type: %String{}}
              }
            }
          }
        }
      }
    end
  end

  test "Operation names are unique" do
    valid_document = """
      query getDogName {
        dog {
          name
        }
      }

      query getOwnerName {
        dog {
          owner {
            name
          }
        }
      }     
    """

    invalid_document = """
      query getName {
        dog {
          name
        }
      }

      query getName {
        dog {
          owner {
            name
          }
        }
      }
    """

    assert_valid_document(TestSchema.schema, valid_document, nil, nil, "getDogName")
    assert_valid_document(TestSchema.schema, valid_document, nil, nil, "getOwnerName")
    assert_invalid_document(TestSchema.schema, invalid_document, nil, nil, "getName",
      [%{message: "operation names must be unique"}]
    )
  end
end

