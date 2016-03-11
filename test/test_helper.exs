ExUnit.start(exclude: [:skip])

defmodule ExUnit.TestHelpers do
  import ExUnit.Assertions

  alias GraphQL.Lang.Parser
  alias GraphQL.Validation.Validator

  def stringify_keys(map) when is_map(map) do
    Enum.reduce(map, %{}, fn({k, v}, acc) -> Map.put(acc, stringify_key(k), stringify_keys(v)) end)
  end
  def stringify_keys(list) when is_list(list) do
    Enum.map(list, &stringify_keys/1)
  end
  def stringify_keys(x), do: x

  def stringify_key(key) when is_atom(key), do: to_string(key)
  def stringify_key(key), do: key

  def assert_parse(input_string, expected_output, type \\ :ok) do
    assert Parser.parse(input_string) == {type, expected_output}
  end

  def assert_execute({query, schema}, expected_output) do
    assert_execute({query, schema, %{}}, expected_output)
  end

  def assert_execute({query, schema, data}, expected_output) do
    assert_execute({query, schema, data, %{}}, expected_output)
  end

  def assert_execute({query, schema, data, variables}, expected_output) do
    assert_execute({query, schema, data, variables, nil}, expected_output)
  end

  def assert_execute({query, schema, data, variables, operation}, expected_output) do
    assert(GraphQL.execute(schema, query, data, variables, operation) ==
      {:ok, %{data: stringify_keys(expected_output)}})
  end

  def assert_execute_error({query, schema}, expected_output) do
    assert_execute_error({query, schema, %{}}, expected_output)
  end

  def assert_execute_error({query, schema, data}, expected_output) do
    assert GraphQL.execute(schema, query, data) == {:error, %{errors: stringify_keys(expected_output)}}
  end

  def assert_valid_document(schema, document, root_value \\ %{}, variable_values \\ %{}, operation_name \\ nil) do
    {:ok, document_ast} = Parser.parse(document)
    assert Validator.validate(schema, document_ast, root_value, variable_values, operation_name) == :ok
  end

  def assert_invalid_document(schema, document, root_value \\ %{}, variable_values \\ %{}, operation_name \\ nil, errors) do
    {:ok, document_ast} = Parser.parse(document)
    assert Validator.validate(schema, document_ast, root_value, variable_values, operation_name) == {:error, errors}
  end
end
