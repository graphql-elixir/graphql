defmodule GraphQL.Lang.Lexer.LexerTest do
  use ExUnit.Case, async: true

  def assert_tokens(input, tokens) do
    case :graphql_lexer.string(input) do
      {:ok, output, _} ->
        assert output == tokens
      {:error, {_, :graphql_lexer, output}, _} ->
        assert output == tokens
    end
  end

  # Ignored tokens
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

  # Lexical tokens
  test "Punctuator" do
    assert_tokens '!',              [{ :"!", 1 }]
    assert_tokens '$',              [{ :"$", 1 }]
    assert_tokens '(',              [{ :"(", 1 }]
    assert_tokens ')',              [{ :")", 1 }]
    assert_tokens ':',              [{ :":", 1 }]
    assert_tokens '=',              [{ :"=", 1 }]
    assert_tokens ':',              [{ :":", 1 }]
    assert_tokens '@',              [{ :"@", 1 }]
    assert_tokens '[',              [{ :"[", 1 }]
    assert_tokens ']',              [{ :"]", 1 }]
    assert_tokens '{',              [{ :"{", 1 }]
    assert_tokens '}',              [{ :"}", 1 }]
    assert_tokens '|',              [{ :"|", 1 }]
    assert_tokens '...',            [{ :"...", 1  }]
  end

  test "Name" do
    assert_tokens '_',              [{ :name, 1, '_' }]
    assert_tokens 'a',              [{ :name, 1, 'a' }]
    assert_tokens 'Z',              [{ :name, 1, 'Z' }]
    assert_tokens 'foo',            [{ :name, 1, 'foo' }]
    assert_tokens 'Foo',            [{ :name, 1, 'Foo' }]
    assert_tokens '_foo',           [{ :name, 1, '_foo' }]
    assert_tokens 'foo0',           [{ :name, 1, 'foo0' }]
    assert_tokens '_fu_Ba_QX_2',    [{ :name, 1, '_fu_Ba_QX_2' }]
  end

  test "Literals" do
    assert_tokens 'query',          [{ :"query", 1 }]
    assert_tokens 'mutation',       [{ :"mutation", 1 }]
    assert_tokens 'fragment',       [{ :"fragment", 1 }]
    assert_tokens 'on',             [{ :"on", 1 }]
    assert_tokens 'type',           [{ :"type", 1 }]
  end

  test "IntValue" do
    assert_tokens '0',              [{ :int_value, 1, '0' }]
    assert_tokens '-0',             [{ :int_value, 1, '-0' }]
    assert_tokens '-1',             [{ :int_value, 1, '-1' }]
    assert_tokens '2340',           [{ :int_value, 1, '2340' }]
    assert_tokens '56789',          [{ :int_value, 1, '56789' }]
  end

  test "FloatValue" do
    assert_tokens '0.0',            [{ :float_value, 1, '0.0' }]
    assert_tokens '-0.1',           [{ :float_value, 1, '-0.1' }]
    assert_tokens '0.1',            [{ :float_value, 1, '0.1' }]
    assert_tokens '2.340',          [{ :float_value, 1, '2.340' }]
    assert_tokens '5678.9',         [{ :float_value, 1, '5678.9' }]
    assert_tokens '1.23e+45',       [{ :float_value, 1, '1.23e+45' }]
    assert_tokens '1.23E-45',       [{ :float_value, 1, '1.23E-45' }]
    assert_tokens '0.23E-45',       [{ :float_value, 1, '0.23E-45' }]
  end

  test "StringValue" do
    assert_tokens '""',             [{ :string_value, 1, '""' }]
    assert_tokens '"a"',            [{ :string_value, 1, '"a"' }]
    assert_tokens '"\u000f"',       [{ :string_value, 1, '"\u000f"' }]
    assert_tokens '"\t"',           [{ :string_value, 1, '"\t"' }]
    assert_tokens '"\\""',          [{ :string_value, 1, '"\\""' }]
    assert_tokens '"a\\n"',         [{ :string_value, 1, '"a\\n"' }]
  end

  test "BooleanValue" do
    assert_tokens 'true',           [{ :boolean_value, 1, 'true' }]
    assert_tokens 'false',          [{ :boolean_value, 1, 'false' }]
  end

  test "EnumValue" do
    assert_tokens 'null',           [{ :null, 1 }]
    assert_tokens 'ENUM_VALUE',     [{ :name, 1, 'ENUM_VALUE' }]
    assert_tokens 'enum_value',     [{ :name, 1, 'enum_value' }]
  end

  # Sample GraphQL
  test "Simple statement" do
    assert_tokens '{ hero }', [
      { :"{", 1 },
      { :name, 1, 'hero' },
      { :"}", 1 }
    ]
  end

  test "Named query with nested selection set" do
    assert_tokens 'query myName { me { name } }', [
      {:'query', 1},
      {:name, 1, 'myName'},
      {:'{', 1},
      {:name, 1, 'me'},
      {:'{', 1},
      {:name, 1, 'name'},
      {:'}', 1},
      {:'}', 1}
    ]
  end
end
