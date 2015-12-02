ExUnit.start()

defmodule ExUnit.TestHelpers do
  import ExUnit.Assertions

  def assert_parse(input_string, expected_output, type \\ :ok) do
    assert GraphQL.Lang.Parser.parse(input_string) == {type, expected_output}
  end
end
