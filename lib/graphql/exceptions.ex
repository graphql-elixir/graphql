defmodule GraphQL.SyntaxError do
  @moduledoc """
  An error raised when the syntax in a GraphQL query is incorrect.
  """
  defexception line: nil, errors: "Syntax error"

  def message(exception) do
    "#{exception.errors} on line #{exception.line}"
  end
end

defmodule GraphQL.QueryError do 
  @moduledoc """
  An error raised when a field is queried that does not exist
  """

  defexception line: nil, errors: "Query error", param: nil
  def message(exception) do
    ""
  end
end

