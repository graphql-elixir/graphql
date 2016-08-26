defmodule GraphQL.Execution.Variables do
  alias GraphQL.Execution.ASTValue

  @spec extract(map) :: map
  def extract(context) do
    schema = context.schema
    variable_definition_asts = Map.get(context.operation, :variableDefinitions, [])
    input_map = context.variable_values

    reduce_values(schema, variable_definition_asts, input_map)
  end

  @spec reduce_values(GraphQL.Schema.t, map, map) :: map
  defp reduce_values(schema, definition_asts, inputs) do
    Enum.reduce(definition_asts, %{}, fn(ast, result) ->
      key = ast.variable.name.value
      value = get_variable_value(schema, ast, inputs[key])
      Map.put(result, key, value)
    end)
  end

  defp get_variable_value(schema, ast, input_value) do
    type = GraphQL.Schema.type_from_ast(ast.type, schema)
    value_for(ast, type, input_value)
  end

  @spec value_for(map, map, map | nil) :: map | nil
  defp value_for(%{defaultValue: default}, type, nil) do
    ASTValue.value_from_ast(%{value: default}, type, nil)
  end
  defp value_for(_, _, nil), do: nil
  defp value_for(_, type, input) do
    GraphQL.Types.serialize(%{type: type}, input)
  end
end
