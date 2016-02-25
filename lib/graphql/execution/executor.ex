defmodule GraphQL.Execution.Executor do
  @moduledoc ~S"""
  Execute a GraphQL query against a given schema / datastore.

      # iex> GraphQL.execute schema, "{ hello }"
      # {:ok, %{hello: "world"}}
  """

  alias GraphQL.Type.ObjectType
  alias GraphQL.Type.List
  alias GraphQL.Type.Interface
  alias GraphQL.Type.Input
  alias GraphQL.Type.Union

  @doc """
  Execute a query against a schema.

      # iex> GraphQL.execute(schema, "{ hello }")
      # {:ok, %{hello: world}}
  """
  def execute(schema, document, root_value \\ %{}, variable_values \\ %{}, operation_name \\ nil) do
    context = build_execution_context(schema, document, root_value, variable_values, operation_name)
    case context.errors do
      [] -> execute_operation(context, context.operation, root_value)
      _  -> {:error, %{errors: Enum.dedup(context.errors)}}
    end
  end

  defp report_error(context, msg) do
    put_in(context.errors, [%{"message" => msg} | context.errors])
  end

  defp get_variable_values(schema, definition_asts, inputs) do
    Enum.reduce(definition_asts, %{}, fn(ast, result) ->
      name = ast.variable.name.value
      case x = get_variable_value(schema, ast, inputs[name]) do
        nil -> result
        _ -> Map.put(result, name, x)
      end
    end)
  end

  defp get_variable_value(schema, ast, input) do
    type = GraphQL.Schema.type_from_ast(ast.type, schema)
    # todo soooooo much error handling. so much.
    value_for(ast, type, input)
  end

  defp value_for(%{defaultValue: default}, type, nil) do
    value_from_ast(%{value: default}, %{type: type}, nil)
  end
  defp value_for(_, _, nil), do: nil
  defp value_for(_, type, input) do
    GraphQL.Types.serialize(%{type: type}, input)
  end

  defp build_execution_context(schema, document, root_value, variable_values, operation_name) do
    Enum.reduce document.definitions, %{
      schema: schema,
      fragments: %{},
      root_value: root_value,
      operation: nil,
      variable_values: variable_values, # TODO: We need to deeply set keys as strings or atoms. not allow both.
      errors: []
    }, fn(definition, context) ->

      variable_definitions = Map.get(definition, :variableDefinitions, [])
      variable_values = get_variable_values(schema, variable_definitions, variable_values)
      context = Map.put(context, :variable_values, variable_values)

      case definition do
        %{kind: :OperationDefinition} ->
          cond do
            !operation_name && context.operation ->
              report_error(context, "Must provide operation name if query contains multiple operations.")
            !operation_name || definition.name.value === operation_name ->
              put_in(context.operation, definition)
            true -> context
          end
        %{kind: :FragmentDefinition} ->
          put_in(context.fragments[definition.name.value], definition)
      end
    end
  end

  defp execute_operation(context, operation, root_value) do
    type = operation_root_type(context.schema, operation)
    %{fields: fields} = collect_fields(context, type, operation.selectionSet)
    case operation.operation do
      :query        -> {:ok, execute_fields(context, type, root_value, fields)}
      :mutation     -> {:ok, execute_fields_serially(context, type, root_value, fields)}
      :subscription -> {:error, "Subscriptions not currently supported"}
      _             -> {:error, "Can only execute queries, mutations and subscriptions"}
    end
  end

  defp operation_root_type(schema, operation) do
    Map.get(schema, operation.operation)
  end

  defp collect_fields(context, runtime_type, selection_set, field_fragment_map \\ %{fields: %{}, fragments: %{}}) do
    Enum.reduce selection_set[:selections], field_fragment_map, fn(selection, field_fragment_map) ->
      case selection do
        %{kind: :Field} -> put_in(field_fragment_map.fields[field_entry_key(selection)], [selection])
        %{kind: :InlineFragment} ->
          collect_fragment(context, runtime_type, selection, field_fragment_map)
        %{kind: :FragmentSpread} ->
          fragment_name = selection.name.value
          if !field_fragment_map.fragments[fragment_name] do
            field_fragment_map = put_in(field_fragment_map.fragments[fragment_name], true)
            collect_fragment(context, runtime_type, context.fragments[fragment_name], field_fragment_map)
          else
            field_fragment_map
          end
        _ -> field_fragment_map
      end
    end
  end

  defp execute_fields(context, parent_type, source_value, fields) do
    Enum.reduce fields, %{}, fn({field_name, field_asts}, results) ->
      case resolve_field(context, parent_type, source_value, field_asts) do
        :undefined -> results
        value -> Map.put(results, field_name.value, value)
      end
    end
  end

  defp execute_fields_serially(context, parent_type, source_value, fields) do
    # call execute_fields because no async operations yet
    execute_fields(context, parent_type, source_value, fields)
  end

  defp resolve_field(context, parent_type, source, field_asts) do
    field_ast = hd(field_asts)
    field_name = String.to_atom(field_ast.name.value)

    if field_def = field_definition(parent_type, field_name) do
      return_type = field_def.type

      args = argument_values(Map.get(field_def, :args, %{}), Map.get(field_ast, :arguments, %{}), context.variable_values)
      info = %{
        field_name: field_name,
        field_asts: field_asts,
        return_type: return_type,
        parent_type: parent_type,
        schema: context.schema,
        fragments: context.fragments,
        root_value: context.root_value,
        operation: context.operation,
        variable_values: context.variable_values
      }

      resolution = Map.get(field_def, :resolve)
      result = case resolution do
        {mod, fun}    -> apply(mod, fun, [source, args, info])
        {mod, fun, _} -> apply(mod, fun, [source, args, info])
        resolve when is_function(resolve) ->
          resolve.(source, args, info)
        _ ->
          cond do
            resolution ->  resolution
            true -> Map.get(source, field_name, nil)
          end
      end
      complete_value_catching_error(context, return_type, field_asts, info, result)
    else
      :undefined
    end
  end

  defp complete_value_catching_error(context, return_type, field_asts, info, result) do

    # TODO lots of error checking
    complete_value(context, return_type, field_asts, info, result)
  end

  defp complete_value(_, _, _, _, nil), do: nil

  defp complete_value(context, %ObjectType{} = return_type, field_asts, _info, result) do
    sub_field_asts = collect_sub_fields(context, return_type, field_asts)
    execute_fields(context, return_type, result, sub_field_asts.fields)
  end

  defp complete_value(context, %GraphQL.Type.NonNull{ofType: inner_type}, field_asts, info, result) do
    # TODO: Null Checking
    complete_value(context, inner_type, field_asts, info, result)
  end

  defp complete_value(context, %Interface{} = return_type, field_asts, info, result) do
    runtime_type = GraphQL.AbstractType.get_object_type(return_type, result, info.schema)
    sub_field_asts = collect_sub_fields(context, runtime_type, field_asts)
    execute_fields(context, runtime_type, result, sub_field_asts.fields)
  end

  defp complete_value(context, %Union{} = return_type, field_asts, info, result) do
    runtime_type = GraphQL.AbstractType.get_object_type(return_type, result, info.schema)
    sub_field_asts = collect_sub_fields(context, runtime_type, field_asts)
    execute_fields(context, runtime_type, result, sub_field_asts.fields)
  end

  defp complete_value(context, %List{ofType: list_type}, field_asts, info, result) do
    Enum.map result, fn(item) ->
      complete_value_catching_error(context, list_type, field_asts, info, item)
    end
  end

  defp complete_value(_context, return_type, _field_asts, _info, result) do
    GraphQL.Types.serialize(return_type, result)
  end

  defp collect_sub_fields(context, return_type, field_asts) do
    Enum.reduce field_asts, %{fields: %{}, fragments: %{}}, fn(field_ast, field_fragment_map) ->
      if selection_set = Map.get(field_ast, :selectionSet) do
        collect_fields(context, return_type, selection_set, field_fragment_map)
      else
        field_fragment_map
      end
    end
  end

  def maybe_unwrap(item) when is_tuple(item) do
    {result, _} = Code.eval_quoted(item)
    result
  end
  def maybe_unwrap(item), do: item

  defp field_definition(parent_type, field_name) do
    case field_name do
      :__typename -> GraphQL.Type.Introspection.meta(:typename)
      :__schema -> GraphQL.Type.Introspection.meta(:schema)
      :__type -> GraphQL.Type.Introspection.meta(:type)
      _ -> maybe_unwrap(parent_type.fields)[field_name]
    end
  end

  defp argument_values(arg_defs, arg_asts, variable_values) do
    arg_ast_map = Enum.reduce arg_asts, %{}, fn(arg_ast, result) ->
      Map.put(result, String.to_atom(arg_ast.name.value), arg_ast)
    end
    Enum.reduce arg_defs, %{}, fn(arg_def, result) ->
      {arg_def_name, arg_def_type} = arg_def
      if value_ast = arg_ast_map[arg_def_name] do
        Map.put(result, arg_def_name, value_from_ast(value_ast, arg_def_type, variable_values))
      else
        result
      end
    end
  end

  defp value_from_ast(%{value: obj=%{kind: :ObjectValue}}, %{type: type=%Input{}}, variable_values) do
    input_fields = maybe_unwrap(type.fields)
    field_asts = Enum.reduce(obj.fields, %{}, fn(ast, result) ->
      Map.put(result, ast.name.value, ast)
    end)
    Enum.reduce(Map.keys(input_fields), %{}, fn(field_name, result) ->
      field = Map.get(input_fields, field_name)
      field_ast =  Map.get(field_asts, to_string(field_name)) # this feels... brittle.
      inner_result = value_from_ast(field_ast, field, variable_values)
      case inner_result do
        nil -> result
        _ -> Map.put(result, field_name, inner_result)
      end
    end)
  end

  defp value_from_ast(%{value: %{kind: :Variable, name: %{value: value}}}, type, variable_values) do
    variable_value = Map.get(variable_values, value)
    GraphQL.Types.parse_value(type.type, variable_value)
  end

  # if it isn't a variable or object input type, that means it's invalid
  # and we shoud return a nil
  defp value_from_ast(_, %{type: %Input{}}, _) do
    nil
  end

  defp value_from_ast(%{value: %{kind: :ListValue, values: values_ast}}, type, _) do
    GraphQL.Types.parse_value(type.type, Enum.map(values_ast, fn(value_ast) ->
      value_ast.value
    end))
  end

  defp value_from_ast(nil, _, _), do: nil # remove once NonNull is actually done..
  defp value_from_ast(value_ast, type, _) do
    GraphQL.Types.parse_value(type.type, value_ast.value.value)
  end

  defp field_entry_key(field) do
    Map.get(field, :alias, field.name)
  end

  defp collect_fragment(context, runtime_type, selection, field_fragment_map) do
    condition_matches = typecondition_matches?(context, selection, runtime_type)
    if condition_matches do
      collect_fields(context, runtime_type, selection.selectionSet, field_fragment_map)
    else
      field_fragment_map
    end
  end

  defp typecondition_matches?(context, selection, runtime_type) do
    typed_condition = Map.get(selection, :typeCondition)
    |> GraphQL.Schema.type_from_ast(context.schema)

    cond do
      # type_from_ast was :not_found, so ... false. Probably should be a validation error
      typed_condition == :not_found -> false
      # there's no type condition exists, so everything matches
      typed_condition == nil -> true
      GraphQL.Type.is_abstract?(typed_condition) ->
        GraphQL.AbstractType.possible_type?(typed_condition, runtime_type)
      GraphQL.Type.is_named?(typed_condition) ->
        runtime_type.name == typed_condition.name
      true -> false
    end
  end
end
