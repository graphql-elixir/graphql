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
