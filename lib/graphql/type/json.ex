defmodule GraphQL.Type.JSON do
  defstruct name: "JSON", description:
    """
    The `JSON` type represents dynamic objects in JSON.
    """

  def coerce(value), do: value
end

defimpl GraphQL.Types, for: GraphQL.Type.JSON do
  def parse_value(_, value), do: GraphQL.Type.JSON.coerce(value)
  def serialize(_, value), do: GraphQL.Type.JSON.coerce(value)
  def parse_literal(_, v), do: GraphQL.Type.JSON.coerce(v.value)
end
