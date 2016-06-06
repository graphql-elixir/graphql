defmodule GraphQL.Lang.Type.EnumTest do
  use ExUnit.Case, async: true
  import ExUnit.TestHelpers

  alias GraphQL.Type.ObjectType
  alias GraphQL.Type.Int
  alias GraphQL.Type.String

  defmodule TestSchema do
    def color_type do
      %{
        name: "Color",
        values: %{
          "RED": %{value: 0},
          "GREEN": %{value: 1},
          "BLUE": %{value: 2}
        }
      } |>  GraphQL.Type.Enum.new
    end

    def query do
      %ObjectType{
        name: "Query",
        fields: %{
          color_enum: %{
            type: color_type,
            args: %{
              from_enum: %{type: color_type},
              from_int: %{type: %Int{}},
              from_string: %{type: %String{}},
            },
            resolve: fn(_, args) ->
              Map.get(args, :from_enum) ||
              Map.get(args, :from_int) ||
              Map.get(args, :from_string)
            end
          },
          color_int: %{
            type: %Int{},
            args: %{
              from_enum: %{type: color_type},
              from_int: %{type: %Int{}}
            },
            resolve: fn(_, args) ->
              Map.get(args, :from_enum) ||
              Map.get(args, :from_int)
            end
          }
        }
      }
    end

    def schema, do: GraphQL.Schema.new(%{query: query})
  end

  test "enum values are able to be parsed" do
    assert 1 == GraphQL.Types.parse_value(TestSchema.color_type, "GREEN")
  end

  test "enum values are able to be serialized" do
    assert "GREEN" == GraphQL.Types.serialize(TestSchema.color_type, 1)
  end

  test "accepts enum literals as input" do
    {:ok, result} = execute(TestSchema.schema, "{ color_int(from_enum: GREEN) }")
    assert_data(result, %{color_int: 1})
  end

  test "enum may be output type" do
    {:ok, result} = execute(TestSchema.schema, "{ color_enum(from_int: 1) }")
    assert_data(result, %{color_enum: "GREEN"})
  end

  test "enum may be both input and output type" do
    {:ok, result} = execute(TestSchema.schema, "{ color_enum(from_enum: GREEN) }")
    assert_data(result, %{color_enum: "GREEN"})
  end

  @tag :skip # needs type validation
  test "does not accept string literals" do
    {:ok, result} = execute(TestSchema.schema, ~S[{ color_enum(from_enum: "GREEN") }])
    assert_has_error(result, %{message: "replace with actual message"})
  end

  test "does not accept incorrect internal value" do
    {:ok, result} = execute(TestSchema.schema, ~S[{ color_enum(from_string: "GREEN") }])
    assert_data(result, %{color_enum: nil})
  end

  @tag :skip # needs type validation
  test "does not accept internal value in place of enum literal" do
    {:ok, result} = execute(TestSchema.schema, ~S[{ color_enum(from_enum: 1) }])
    assert_has_error(result, %{message: "replace with actual message"})
  end

  @tag :skip # needs type validation
  test "does not accept enum literal in place of int" do
    {:ok, result} = execute(TestSchema.schema, ~S[{ color_enum(from_int: GREEN) }])
    assert_has_error(result, %{message: "replace with actual message"})
  end

  test "accepts JSON string as enum variable" do
    query = "query test($color: Color!) { color_enum(from_enum: $color) }"
    {:ok, result} = execute(TestSchema.schema, query, variable_values: %{"color" => "BLUE"})
    assert_data(result, %{"color_enum" => "BLUE"})
  end

  @tag :skip
  test "accepts enum literals as input arguments to mutations", do: :skipped
  @tag :skip
  test "accepts enum literals as input arguments to subscriptions", do: :skipped
  @tag :skip
  test "does not accept internal value as enum variable", do: :skipped
  @tag :skip
  test "does not accept string variables as enum input", do: :skipped
  @tag :skip
  test "does not accept internal value variable as enum input", do: :skipped

  test "enum value may have an internal value of 0" do
    {:ok, result} = execute(TestSchema.schema, "{ color_enum(from_enum: RED), color_int(from_enum: RED) }")
    assert_data(result, %{color_enum: "RED", color_int: 0})
  end

  test "enum inputs may be nullable" do
    {:ok, result} = execute(TestSchema.schema, "{color_enum, color_int}")
    assert_data(result, %{color_enum: nil, color_int: nil})
  end
end
