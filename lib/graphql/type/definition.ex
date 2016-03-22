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
  @doc """
  Converts a module type (`StarWars.Schema.Character`) to a String (`"Character"`)
  """
  @spec module_to_string(atom) :: String.t
  def module_to_string(module_type) do
    module_type |> Atom.to_string |> String.split(".") |> Enum.reverse |> hd
  end

  @spec implements?(GraphQL.Type.Object.t, GraphQL.Type.Interface.t) :: boolean
  def implements?(object, interface) do
    Map.get(object, :interfaces, [])
    |> Enum.map(fn
      (iface) when is_atom(iface) -> module_to_string(iface)
      (iface) -> iface.name
    end)
    |> Enum.member?(interface.name)
  end

  def is_abstract?(%GraphQL.Type.Union{}), do: true
  def is_abstract?(%GraphQL.Type.Interface{}), do: true
  def is_abstract?(_), do: false

  def is_named?(%GraphQL.Type.Object{}), do: true
  def is_named?(_), do: false

  def is_composite_type?(%GraphQL.Type.Object{}), do: true
  def is_composite_type?(%GraphQL.Type.Interface{}), do: true
  def is_composite_type?(%GraphQL.Type.Union{}), do: true
  def is_composite_type?(_), do: false
end
