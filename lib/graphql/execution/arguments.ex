
defmodule GraphQL.Execution.Arguments do
  alias GraphQL.Execution.ASTValue

  def argument_values(arg_defs, arg_asts, variable_values) do
    arg_ast_map = Enum.reduce arg_asts, %{}, fn(arg_ast, result) ->
      Map.put(result, String.to_atom(arg_ast.name.value), arg_ast)
    end
    Enum.reduce(arg_defs, %{}, fn(arg_def, result) ->
      {arg_def_name, arg_def_type} = arg_def
      value_ast = Map.get(arg_ast_map, arg_def_name)

      value = ASTValue.value_from_ast(value_ast, arg_def_type.type, variable_values)
      value = if is_nil(value) do
        Map.get(arg_def_type, :defaultValue)
      else
        value
      end
      if is_nil(value) do
        result
      else
        Map.put(result, arg_def_name, value)
      end
    end)
  end
end
