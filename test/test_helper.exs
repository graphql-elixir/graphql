ExUnit.start(exclude: [:skip])

defmodule ExUnit.TestHelpers do
  import ExUnit.Assertions

  alias GraphQL.Lang.Parser
  alias GraphQL.Execution.Executor

  def assert_parse(input_string, expected_output, type \\ :ok) do
    assert Parser.parse(input_string) == {type, expected_output}
  end

  def assert_execute({query, schema}, expected_output) do
    {:ok, doc} = Parser.parse(query)
    assert Executor.execute(schema, doc) == {:ok, expected_output}
  end

  def assert_execute({query, schema, data}, expected_output) do
    {:ok, doc} = Parser.parse(query)
    assert Executor.execute(schema, doc, data) == {:ok, expected_output}
  end

  def assert_execute_error({query, schema}, expected_output) do
    {:ok, doc} = Parser.parse(query)
    assert Executor.execute(schema, doc) == {:error, expected_output}
  end

  def assert_execute_error({query, schema, data}, expected_output) do
    {:ok, doc} = Parser.parse(query)
    assert Executor.execute(schema, doc, data) == {:error, expected_output}
  end


end
