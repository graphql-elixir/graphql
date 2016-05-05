ExUnit.start(exclude: [:skip])

defmodule ExUnit.TestHelpers do
  import ExUnit.Assertions

  alias GraphQL
  alias GraphQL.Lang.Parser

  def stringify_keys(map) when is_map(map) do
    Enum.reduce(map, %{}, fn({k, v}, acc) -> Map.put(acc, stringify_key(k), stringify_keys(v)) end)
  end
  def stringify_keys(list) when is_list(list) do
    Enum.map(list, &stringify_keys/1)
  end
  def stringify_keys(x), do: x

  def stringify_key(key) when is_atom(key), do: to_string(key)
  def stringify_key(key), do: key

  def execute(schema, query, opts \\ []) do
    GraphQL.execute_with_opts(schema, query, opts)
  end

  def assert_data(result, expected) do
    assert(
      result[:data] == stringify_keys(expected),
      message: "Expected result[:data] to equal #{inspect stringify_keys(expected)} but was #{inspect result[:data]}"
    )
  end

  def assert_has_error(result, expected) do
    assert(
      Enum.member?(result[:errors], stringify_keys(expected)),
      message: "Expected result[:errors] to contain #{inspect expected}"
    )
  end

  def assert_parse(input_string, expected_output, type \\ :ok) do
    assert Parser.parse(input_string) == {type, expected_output}
  end
end
