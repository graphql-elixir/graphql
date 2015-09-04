defmodule GraphqlTest do
  use ExUnit.Case

  def assert_parse(input_string, expected_output) do
    assert Graphql.parse(input_string) == expected_output
  end

  test "parse char list" do
    assert_parse '{ hero }', [ {[ 'hero' ]} ]
  end

  test "parse string" do
    assert_parse "{ hero }", [ {[ 'hero' ]} ]
  end
end
