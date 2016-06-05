
defmodule GraphQL.Lang.AST.DocumentInfo do

  defstruct schema: nil,
            document: nil,
            lookups: %{}

  def new(schema, document) do
    %GraphQL.Lang.AST.DocumentInfo{schema: schema, lookups: precompute_lookups(schema, document)}
  end

  def get_fragment_definition(document_info, name) do
    document_info.lookups[:fragment_definitions][name]
  end

  defp precompute_lookups(_schema, document) do
    %{
      fragment_definitions: Enum.reduce(document.definitions, %{}, fn(definition, acc) ->
        if definition[:kind] == :FragmentDefinition do
          put_in(acc[definition.name.value], definition)
        else
          acc
        end
      end)
    } 
  end
end
