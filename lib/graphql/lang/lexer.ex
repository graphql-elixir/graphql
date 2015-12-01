defmodule GraphQL.Lang.Lexer do
  @moduledoc ~S"""
  GraphQL lexer implemented with leex.

  Tokenise a GraphQL query

      iex> GraphQL.tokenize("{ hello }")
      [{ :"{", 1 }, { :name, 1, 'hello' }, { :"}", 1 }]
  """

  @doc """
  Tokenize the input string into a stream of tokens.

      iex> GraphQL.tokenize("{ hello }")
      [{ :"{", 1 }, { :name, 1, 'hello' }, { :"}", 1 }]

  """
  def tokenize(input_string) when is_binary(input_string) do
    input_string |> to_char_list |> tokenize
  end

  def tokenize(input_string) do
    {:ok, tokens, _} = :graphql_lexer.string input_string
    tokens
  end
end
