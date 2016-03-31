defmodule GraphQL.Type.ObjectType do
  @type t :: %GraphQL.Type.ObjectType{
    name: binary,
    description: binary | nil,
    fields: Map.t | function,
    interfaces: [GraphQL.Interface.t] | nil,
    isTypeOf: ((any) -> boolean)
  }
  defstruct name: "", description: "", fields: %{}, interfaces: [], isTypeOf: nil

  defimpl String.Chars do
    def to_string(obj), do: obj.name
  end
end
