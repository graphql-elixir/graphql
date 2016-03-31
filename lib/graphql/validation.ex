
defmodule GraphQL.Validation do
  @moduledoc ~S"""
  Helpers that are useful within validation rules.
  """

  @doc """
  Returns an updated accumulator containing the validation error.
  """
  def report_error(acc, error) do
    %{acc | validation_errors: [error] ++ acc[:validation_errors]}
  end
end
