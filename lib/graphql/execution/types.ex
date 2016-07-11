
defmodule GraphQL.Execution.Types do
  def unwrap_type(type) when is_atom(type), do: type.type
  def unwrap_type(type), do: type
end
