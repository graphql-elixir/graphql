defmodule GraphQL.Type.List do
  @type t :: %{ofType: map}
  defstruct ofType: nil
end

defimpl GraphQL.Types, for: GraphQL.Type.List do
  def parse_value(_, nil), do: nil
  def parse_value(_, value) when is_list(value), do: value
  def parse_value(_, value), do: List.wrap(value)
  def serialize(_, value), do: value
  def parse_literal(_, v), do: v.value
end
