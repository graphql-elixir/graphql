ExUnit.start()

defmodule ExUnit.TestHelpers do
  import ExUnit.Assertions

  def assert_tokens(input, tokens) do
    case :graphql_lexer.string(input) do
      {:ok, output, _} ->
        assert output == tokens
      {:error, {_, :graphql_lexer, output}, _} ->
        assert output == tokens
    end
  end

  def assert_parse(input_string, expected_output, type \\ :ok) do
    assert GraphQL.parse(input_string) == {type, expected_output}
  end
end
