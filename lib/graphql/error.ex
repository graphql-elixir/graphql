defmodule GraphQL.Errors do
  @moduledoc """
  Represents a set of errors that have occured.
  """
  @type t :: %{errors: list(GraphQL.Error.t)}
  defstruct errors: []

  @doc """
  Generates a new Errors structure using the passed in errors as the contents

  ## Examples

      iex> GraphQL.Errors.new([%GraphQL.Error{message: "GraphQL: syntax error before: '}' on line 1", line_number: 1}])
      %GraphQL.Errors{errors: [%GraphQL.Error{line_number: 1,
          message: "GraphQL: syntax error before: '}' on line 1"}]}
  """
  @spec new(list(GraphQL.Error.t)) :: GraphQL.Errors.t
  def new(errors) when is_list(errors) do
    %GraphQL.Errors{errors: errors}
  end

  @spec new(GraphQL.Error.t) :: GraphQL.Errors.t
  def new(error) do
    %GraphQL.Errors{errors: [error]}
  end
end

defmodule GraphQL.Error do
  @moduledoc """
  Represents the data structure for a single error.

  ## Examples

      iex> %GraphQL.Error{message: "GraphQL: syntax error before: '}' on line 1", line_number: 1}
      %GraphQL.Error{line_number: 1,
       message: "GraphQL: syntax error before: '}' on line 1"}
  """
  @type t :: %{message: String.t}
  defstruct message: "", line_number: 0
end
