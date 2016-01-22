ExUnit.start(exclude: [:skip])

defmodule ExUnit.TestHelpers do
  import ExUnit.Assertions

  alias GraphQL.Lang.Parser

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
    assert GraphQL.execute(schema, query, data, variables) == {:ok, %{data: expected_output}}
  end

  def assert_execute_error({query, schema}, expected_output) do
    assert_execute_error({query, schema, %{}}, expected_output)
  end

  def assert_execute_error({query, schema, data}, expected_output) do
    assert GraphQL.execute(schema, query, data) == {:error, %{errors: expected_output}}
  end
end
