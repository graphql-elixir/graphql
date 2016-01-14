defmodule GraphQL.Type.String do
  defstruct name: "String", description: ":words:"

  def coerce(value), do: to_string(value)
end

defimpl GraphQL.Types, for: GraphQL.Type.String do
  def parse_value(_, value), do: GraphQL.Type.String.coerce(value)
  def serialize(_, value), do: GraphQL.Type.String.coerce(value)
end
