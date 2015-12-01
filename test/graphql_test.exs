defmodule GraphQLTest do
  use ExUnit.Case, async: true
  doctest GraphQL

  import ExUnit.TestHelpers

  test "Report error with message" do
    assert_parse "a", %{errors: [%{message: "GraphQL: syntax error before: \"a\" on line 1", line_number: 1}]}, :error
    assert_parse "a }", %{errors: [%{message: "GraphQL: syntax error before: \"a\" on line 1", line_number: 1}]}, :error
    # assert_parse "", %{errors: [%{message: "GraphQL: syntax error before:  on line 1", line_number: 1}]}, :error
    assert_parse "{}", %{errors: [%{message: "GraphQL: syntax error before: '}' on line 1", line_number: 1}]}, :error
  end
end
