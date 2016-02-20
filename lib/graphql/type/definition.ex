# TODO think of a better name for this protocol:
# Typed, TypeProtocol
defprotocol GraphQL.Types do
  @fallback_to_any true
  def parse_value(type, value)
  def serialize(type, value)
end

defprotocol GraphQL.AbstractType do
  @type t :: GraphQL.Type.Union.t | GraphQL.Type.Interface.t

  @spec possible_type?(GraphQL.AbstractType.t, GraphQL.Type.ObjectType.t) :: boolean
  def possible_type?(abstract_type, object)

  @spec get_object_type(GraphQL.AbstractType.t, %{}, GraphQL.Schema.t) :: GraphQL.Type.ObjectType.t
  def get_object_type(abstract_type, object, schema)
end

defimpl GraphQL.Types, for: Any do
  def parse_value(_, v), do:  v
  def serialize(_, v), do: v
end

defmodule GraphQL.Type do
  defmodule ObjectType do
    @type t :: %GraphQL.Type.ObjectType{
      name: binary,
      description: binary | nil,
      fields: Map,
      interfaces: [GraphQL.AbstractType.t] | nil,
      isTypeOf: (any -> boolean)
    }
    defstruct name: "", description: "", fields: %{}, interfaces: [], isTypeOf: nil
  end

  defmodule ScalarType do
    defstruct name: "", description: ""
  end

  defmodule List do
    defstruct ofType: nil
  end

  defmodule NonNull do
    defstruct ofType: nil
  end

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
