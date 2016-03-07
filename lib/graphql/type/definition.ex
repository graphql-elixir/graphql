# TODO think of a better name for this protocol:
# Typed, TypeProtocol
defprotocol GraphQL.Types do
  @fallback_to_any true
  def parse_value(type, value)
  def parse_literal(type, value)
  def serialize(type, value)
end

defimpl GraphQL.Types, for: Any do
  def parse_value(_, v), do:  v
  def parse_literal(_, v), do: v.value
  def serialize(_, v), do: v
end

defmodule GraphQL.Type do
  @spec implements?(GraphQL.Type.ObjectType.t, GraphQL.Type.Interface.t) :: boolean
  def implements?(object, interface) do
    Map.get(object, :interfaces, [])
    |> Enum.map(&(&1.name))
    |> Enum.member?(interface.name)
  end

  def is_abstract?(%GraphQL.Type.Union{}), do: true
  def is_abstract?(%GraphQL.Type.Interface{}), do: true
  def is_abstract?(_), do: false

  def is_named?(%GraphQL.Type.ObjectType{}), do: true
  def is_named?(_), do: false
end


