defmodule GraphqlLexerTest do
  use ExUnit.Case

  def assert_tokens(input, tokens) do
    {:ok, output, _} = :graphql_lexer.string(input)
    assert output == tokens
  end

  test "WhiteSpace is ignored" do
    assert_tokens '\x{0009}', [] # horizontal tab
    assert_tokens '\x{000B}', [] # vertical tab
    assert_tokens '\x{000C}', [] # form feed
    assert_tokens '\x{0020}', [] # space
    assert_tokens '\x{00A0}', [] # non-breaking space
  end

  test "LineTerminator is ignored" do
    assert_tokens '\x{000A}', [] # new line
    assert_tokens '\x{000D}', [] # carriage return
    assert_tokens '\x{2028}', [] # line separator
    assert_tokens '\x{2029}', [] # paragraph separator
  end

  test "Comment is ignored" do
    assert_tokens '# some comment', []
  end

  test "Comma is ignored" do
    assert_tokens ',', []
  end
end
