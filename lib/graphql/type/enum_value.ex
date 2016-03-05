defmodule GraphQL.Type.EnumValue do
  @type t :: %GraphQL.Type.EnumValue{
    name: binary,
    description: binary,
    value: any
  }
  defstruct name: "", value: "", description: ""
end
