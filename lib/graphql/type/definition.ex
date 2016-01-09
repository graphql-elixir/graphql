defprotocol GraphQL.Types do
  @fallback_to_any true
  def parse_value(_,_)
  def serialize(_,_)
end

defimpl GraphQL.Types, for: Any do
  def parse_value(_,v), do:  v
  def serialize(_,v), do: v
end

defmodule GraphQL.ObjectType do
  defstruct name: "", description: "", fields: %{}
end

defmodule GraphQL.List do
  defstruct of_type: nil
end


defmodule GraphQL.Type do

  defmodule ScalarType do
    defstruct name: "", description: ""
  end

  defmodule NonNull do
    defstruct of_type: nil
  end

  def string do
    %ScalarType{
      name: "String",
      description: "Strings and stuff"
    }
  end
end
