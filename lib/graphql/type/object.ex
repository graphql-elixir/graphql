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

  defimpl GraphQL.Execution.Completion do
    alias GraphQL.Execution.Selection

    def complete_value(return_type, context, field_asts, _info, result) do
      Selection.complete_sub_fields(return_type, context, field_asts, result)
    end
  end
end

