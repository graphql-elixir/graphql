defmodule GraphQL.Execution.Executor.VariableTest do
  use ExUnit.Case, async: true

  import ExUnit.TestHelpers

  alias GraphQL.Schema
  alias GraphQL.Type.ObjectType
  alias GraphQL.Type.List
  alias GraphQL.Type.NonNull
  alias GraphQL.Type.String
  alias GraphQL.Type.Input

  defmodule GraphQL.Type.TestComplexScalar do
    defstruct name: "ComplexScalar", description: ""
  end
  # TODO: Why can't I have a defimpl in here?
  # Should I put this in a support file?
  alias GraphQL.Type.TestComplexScalar

  def test_input_object do
    %Input{
      name: "TestInputObject",
      fields: %{
        a: %{ type: %String{} },
        b: %{ type: %List{ofType: %String{} } },
        c: %{ type: %NonNull{ofType: %String{} } },
        d: %{ type: %TestComplexScalar{} }
      }
    }
  end

  def test_nested_input_object do
    %Input{
      name: "TestNestedInputObject",
      fields: %{
        na: %{ type: %NonNull{ofType: test_input_object } },
        nb: %{ type: %NonNull{ofType: %String{} } }
      }
    }
  end

  def test_type do
    %ObjectType{
      name: "TestType",
      fields: %{
        field_with_object_input: %{
          type: %String{},
          args: %{
            input: %{ type: test_input_object }
          },
          resolve: fn(_, %{input: input}, _) -> input end
        },
        field_with_nullable_string_input: %{
          type: %String{},
          args: %{
            input: %{ type: %String{} }
          },
          resolve: fn(_, %{input: input}, _) -> input end
        },
        field_with_nonnullable_string_input: %{
          type: %String{},
          args: %{
            input: %{ type: %NonNull{ofType: %String{} } }
          },
          resolve: fn(_, %{input: input}, _) -> input end
        },
        field_with_default_parameter: %{
          type: %String{},
          args: %{
            input: %{ type: %String{}, defaultValue: "Hello World" }
          },
          resolve: fn(_, %{input: input}, _) -> input end
        },
        field_with_nested_input: %{
          type: %String{},
          args: %{
            input: %{ type: test_nested_input_object, defaultValue: "Hello World" }
          },
          resolve: fn(_, %{input: input}, _) -> input end
        },
        list: %{
          type: %String{},
          args: %{
            input: %{ type: %List{ofType: %String{} } }
          },
          resolve: fn(_, %{input: input}, _) -> input end
        },
        nnList: %{
          type: %String{},
          args: %{
            input: %{ type: %NonNull{ofType: %List{ofType: %String{} } } }
          },
          resolve: fn(_, %{input: input}, _) -> input end
        },
        listNN: %{
          type: %String{},
          args: %{
            input: %{ type: %List{ofType: %NonNull{ofType: %String{} } } }
          },
          resolve: fn(_, %{input: input}, _) -> input end
        },
        nnListNN: %{
          type: %String{},
          args: %{
            input: %{ type: %NonNull{ofType: %List{ofType: %NonNull{ofType: %String{} } } } }
          },
          resolve: fn(_, %{input: input}, _) -> input end
        }
      } # /fields
    }
  end

  def schema do
    %Schema{ query: test_type }
  end

  test "Handles objects and nullability using inline structs executes with complex input" do
    query = """
    {
      field_with_object_input(input: {a: "foo", b: ["bar"], c: "baz"})
    }
    """

    assert_execute {query, schema},
    # the inner value should be a string as part of String.coerce.
    # for now just get the right data..
    %{"field_with_object_input" => %{"a": "foo", "b": ["bar"], "c": "baz"}}
  end

  test "Handles objects and nullability using inline structs properly parses single value to list" do
    query = """
    {
      field_with_object_input(input: {a: "foo", b: "bar", c: "baz"})
    }
    """
    assert_execute {query, schema},
    %{"field_with_object_input" => %{"a": "foo", "b": ["bar"], "c": "baz"}}
  end

  test "Handles objects and nullability using inline structs does not use incorrect value" do
    query = """
    {
      field_with_object_input(input: ["foo", "bar", "baz"])
    }
    """
    assert_execute {query, schema}, %{"field_with_object_input" => nil}
  end

  def using_variables_query do  """
    query q($input: TestInputObject) {
      field_with_object_input(input: $input)
    }
  """ end
  test "Handles objects and nullability using variables executes with complex input" do
    params = %{ "input" => %{ a: 'foo', b: [ 'bar' ], c: 'baz' } }
    assert_execute {using_variables_query, schema, nil, params},
    %{"field_with_object_input" => %{"a" => 'foo', "b" => ['bar'], "c" => 'baz'}}
  end

  test "Handles objects and nullability using variables uses default value when not provided" do
    query = """
      query q($input: TestInputObject = {a: "foo", b: ["bar"], c: "baz"}) {
        field_with_object_input(input: $input)
      }
    """
    assert_execute {query, schema},
    %{"field_with_object_input" => %{"a" => "foo", "b" => ["bar"], "c" => "baz"}}
  end
end
