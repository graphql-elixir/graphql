defmodule GraphQL.Execution.Executor do
  @moduledoc ~S"""
  Execute a GraphQL query against a given schema / datastore.

      # iex> GraphQL.execute schema, "{ hello }"
      # {:ok, %{hello: "world"}}
  """

  @doc """
  Execute a query against a schema.

      # iex> GraphQL.execute(schema, "{ hello }")
      # {:ok, %{hello: world}}
  """
  def execute(schema, document, root_value \\ %{}, variable_values \\ %{}, operation_name \\ nil) do
    context = build_execution_context(schema, document, root_value, variable_values, operation_name)
    case context.errors do
      [] -> execute_operation(context, context.operation, root_value)
      _  -> {:error, %{errors: context.errors}}
    end
  end

  defp report_error(context, msg) do
    put_in(context.errors, [%{message: msg} | context.errors])
  end

  defp build_execution_context(schema, document, root_value, variable_values, operation_name) do
    Enum.reduce document.definitions, %{
      schema: schema,
      fragments: %{},
      root_value: root_value,
      operation: nil,
      variable_values: variable_values,
      errors: []
    }, fn(definition, context) ->
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
        nil -> results
        value -> Map.put results, String.to_atom(field_name.value), value
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

    if field_def = field_definition(context.schema, parent_type, field_name) do
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
      resolution = Map.get(field_def, :resolve, source[field_name])
      result = case resolution do
        {mod, fun}    -> apply(mod, fun, [source, args, info])
        {mod, fun, _} -> apply(mod, fun, [source, args, info])
        resolve when is_function(resolve) -> resolve.(source, args, info)
        _ -> resolution
      end
      complete_value_catching_error(context, return_type, field_asts, info, result)
    end
  end

  defp complete_value_catching_error(context, return_type, field_asts, info, result) do
    # TODO lots of error checking
    complete_value(context, return_type, field_asts, info, result)
  end

  defp complete_value(context, %GraphQL.ObjectType{} = return_type, field_asts, _info, result) do
    sub_field_asts = collect_sub_fields(context, return_type, field_asts)
    execute_fields(context, return_type, result, sub_field_asts.fields)
  end

  defp complete_value(context, %GraphQL.List{of_type: list_type}, field_asts, info, result) do
    Enum.map result, fn(item) ->
      complete_value_catching_error(context, list_type, field_asts, info, item)
    end
  end

  defp complete_value(_context, _return_type, _field_asts, _info, result) do
    result
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

  defp maybe_unwrap(item) when is_tuple(item) do
    {result,_} = Code.eval_quoted(item)
    result
  end
  defp maybe_unwrap(item), do: item

  defp field_definition(_schema, parent_type, field_name) do
    # TODO deal with introspection
    maybe_unwrap(parent_type.fields)[field_name]
  end

  defp argument_values(arg_defs, arg_asts, variable_values) do
    arg_ast_map = Enum.reduce arg_asts, %{}, fn(arg_ast, result) ->
      Map.put(result, String.to_atom(arg_ast.name.value), arg_ast)
    end
    Enum.reduce arg_defs, %{}, fn(arg_def, result) ->
      {arg_def_name, arg_def_type} = arg_def
      if value_ast = arg_ast_map[arg_def_name] do
        Map.put result, arg_def_name, value_from_ast(value_ast, arg_def_type, variable_values)
      else
        result
      end
    end
  end

  defp value_from_ast(value_ast, _type, _variable_values) do
    value_ast.value.value
  end

  defp field_entry_key(field) do
    Map.get(field, :alias, field.name)
  end

  defp collect_fragment(context, runtime_type, selection, field_fragment_map) do
    condition_matches = typecondition_matches?(selection, runtime_type)
    if condition_matches do
      collect_fields(context, runtime_type, selection.selectionSet, field_fragment_map)
    else
      field_fragment_map
    end
  end

  defp typecondition_matches?(selection, runtime_type) do
    type = Map.get(selection, :typeCondition, :no_type)
    cond do
      type == :no_type -> true
      type.name.value === runtime_type.name -> true
      true -> false
    end
  end
end
