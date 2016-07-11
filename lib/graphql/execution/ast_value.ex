
defmodule GraphQL.Execution.ASTValue do
  alias GraphQL.Type.NonNull
  alias GraphQL.Type.List
  alias GraphQL.Type.Input
  alias GraphQL.Type.NonNull
  alias GraphQL.Type.CompositeType

  def value_from_ast(value_ast, %NonNull{ofType: inner_type}, variable_values) do
    value_from_ast(value_ast, inner_type, variable_values)
  end

  def value_from_ast(%{value: obj=%{kind: :ObjectValue}}, type=%Input{}, variable_values) do
    input_fields = CompositeType.get_fields(type)
    field_asts = Enum.reduce(obj.fields, %{}, fn(ast, result) ->
      Map.put(result, ast.name.value, ast)
    end)
    Enum.reduce(Map.keys(input_fields), %{}, fn(field_name, result) ->
      field = Map.get(input_fields, field_name)
      field_ast =  Map.get(field_asts, to_string(field_name)) # this feels... brittle.
      inner_result = value_from_ast(field_ast, field.type, variable_values)
      case inner_result do
        nil -> result
        _ -> Map.put(result, field_name, inner_result)
      end
    end)
  end

  def value_from_ast(%{value: %{kind: :Variable, name: %{value: value}}}, type, variable_values) do
    case Map.get(variable_values, value) do
      nil -> nil
      variable_value -> GraphQL.Types.parse_value(type, variable_value)
    end
  end

  # if it isn't a variable or object input type, that means it's invalid
  # and we shoud return a nil
  def value_from_ast(_, %Input{}, _), do: nil

  def value_from_ast(%{value: %{kind: :ListValue, values: values_ast}}, type, _) do
    GraphQL.Types.parse_value(type, Enum.map(values_ast, fn(value_ast) ->
      value_ast.value
    end))
  end

  def value_from_ast(value_ast, %List{ofType: inner_type}, variable_values) do
    [value_from_ast(value_ast, inner_type, variable_values)]
  end

  def value_from_ast(nil, _, _), do: nil # remove once NonNull is actually done..

  def value_from_ast(value_ast, type, variable_values) when is_atom(type) do
    value_from_ast(value_ast, type.type, variable_values)
  end

  def value_from_ast(value_ast, type, _) do
    GraphQL.Types.parse_literal(type, value_ast.value)
  end
end
