defmodule GraphQL.Type.ObjectType do
  @type t :: %GraphQL.Type.ObjectType{
    name: binary,
    description: binary | nil,
    fields: map,
    interfaces: [GraphQL.Interface.t] | nil,
    isTypeOf: ((any) -> boolean)
  }
  defstruct name: "", description: "", fields: %{}, interfaces: [], isTypeOf: nil
end
