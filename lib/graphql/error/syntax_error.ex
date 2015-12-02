defmodule GraphQL.SyntaxError do
  @moduledoc """
  An error raised when the syntax in a GraphQL query is incorrect.
  """
  defexception line: nil, errors: "Syntax error"

  def message(exception) do
    "#{exception.errors} on line #{exception.line}"
  end
end
