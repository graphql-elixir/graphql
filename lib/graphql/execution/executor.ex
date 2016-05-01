defmodule GraphQL.Execution.Executor do

  alias GraphQL.Schema
  alias GraphQL.Execution.ExecutionContext
  alias GraphQL.Execution.FieldResolver
  alias GraphQL.Type.ObjectType
  alias GraphQL.Type.List
  alias GraphQL.Type.Interface
  alias GraphQL.Type.NonNull
  alias GraphQL.Type.Input
  alias GraphQL.Type.Union
  alias GraphQL.Type.NonNull
  alias GraphQL.Type.CompositeType
  alias GraphQL.Type.AbstractType
  alias GraphQL.Lang.AST.Nodes

  @type result_data :: {:ok, Map}

  @doc """
  Execute a query against a schema.

      # iex> Executor.execute(schema, "{ hello }")
      # {:ok, %{hello: world}}
  """
  @spec execute(GraphQL.Schema.t, GraphQL.Document.t, list) :: result_data | {:error, %{errors: list}}
  def execute(schema, document, opts \\ []) do
    root_value      = Keyword.get(opts, :root_value, %{})
    variable_values = Keyword.get(opts, :variable_values, %{})
    operation_name  = Keyword.get(opts, :operation_name, nil)
    context = ExecutionContext.new(schema, document, root_value, variable_values, operation_name)
    case context.errors do
      [] -> execute_operation(context, context.operation, root_value)
      _  -> {:error, %{errors: Enum.dedup(context.errors)}}
    end
  end

  @spec execute_operation(ExecutionContext.t, Nodes.operation_node, map) :: result_data | {:error, String.t}
  defp execute_operation(context, operation, root_value) do
    type = Schema.operation_root_type(context.schema, operation)
    {context, %{fields: fields}} = collect_selections(context, type, operation.selectionSet)
    case operation.operation do
      :query        ->
        {context, result} = execute_fields(context, type, root_value, fields)
        {:ok, result, context.errors}
      :mutation     ->
        {context, result} = execute_fields_serially(context, type, root_value, fields)
        {:ok, result, context.errors}
      :subscription -> {:error, "Subscriptions not currently supported"}
      _             -> {:error, "Can only execute queries, mutations and subscriptions"}
    end
  end


  defp collect_selections(context, runtime_type, selection_set, field_fragment_map \\ %{fields: %{}, fragments: %{}}) do
    Enum.reduce selection_set[:selections], {context, field_fragment_map}, fn(selection, {context, field_fragment_map}) ->
      collect_selection(context, runtime_type, selection, field_fragment_map)
    end
  end

  defp collect_selection(context, _, %{kind: :Field} = selection, field_fragment_map) do
    field_name = field_entry_key(selection)
    fields = field_fragment_map.fields[field_name] || []
    {context, put_in(field_fragment_map.fields[field_name], [selection | fields])}
  end

  defp collect_selection(context, runtime_type, %{kind: :InlineFragment} = selection, field_fragment_map) do
    collect_fragment(context, runtime_type, selection, field_fragment_map)
  end

  defp collect_selection(context, runtime_type, %{kind: :FragmentSpread} = selection, field_fragment_map) do
    fragment_name = selection.name.value
    if !field_fragment_map.fragments[fragment_name] do
      field_fragment_map = put_in(field_fragment_map.fragments[fragment_name], true)
      collect_fragment(context, runtime_type, context.fragments[fragment_name], field_fragment_map)
    else
      {context, field_fragment_map}
    end
  end

  defp collect_selection(context, _, _, field_fragment_map), do: {context, field_fragment_map}

  @spec execute_fields(ExecutionContext.t, atom | Map, any, any) :: {ExecutionContext.t, map}
  defp execute_fields(context, parent_type, source_value, fields) when is_atom(parent_type) do
    execute_fields(context, apply(parent_type, :type, []), source_value, fields)
  end

  @spec execute_fields(ExecutionContext.t, atom | Map, any, any) :: {ExecutionContext.t, map}
  defp execute_fields(context, parent_type, source_value, fields) do
    Enum.reduce fields, {context, %{}}, fn({field_name_ast, field_asts}, {context, results}) ->
      case resolve_field(context, parent_type, source_value, field_asts) do
        {context, :undefined} -> {context, results}
        {context, value} -> {context, Map.put(results, field_name_ast.value, value)}
      end
    end
  end

  @spec execute_fields_serially(ExecutionContext.t, atom, map, any) :: {ExecutionContext.t, map}
  defp execute_fields_serially(context, parent_type, source_value, fields) do
    # call execute_fields because no async operations yet
    execute_fields(context, parent_type, source_value, fields)
  end

  defp resolve_field(context, parent_type, source, field_asts) do
    field_ast = hd(field_asts)
    # FIXME: possible memory leak
    field_name = String.to_atom(field_ast.name.value)

    if field_def = field_definition(parent_type, field_name) do
      return_type = field_def.type

      args = argument_values(
        Map.get(field_def, :args, %{}),
        Map.get(field_ast, :arguments, %{}),
        context.variable_values
      )

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

      case FieldResolver.resolve(field_def, source, args, info) do
        {:ok, result} ->
          complete_value_catching_error(context, return_type, field_asts, info, result)
        {:error, message} ->
          {ExecutionContext.report_error(context, message), nil}
      end
    else
      {context, :undefined}
    end
  end

  @spec complete_value_catching_error(ExecutionContext.t, any, GraphQL.Document.t, any, map) :: {ExecutionContext.t, map | nil}
  defp complete_value_catching_error(context, return_type, field_asts, info, result) do
    # TODO lots of error checking
    complete_value(context, return_type, field_asts, info, result)
  end

  @spec complete_value(ExecutionContext.t, any, any, any, nil) :: {ExecutionContext.t, nil}
  defp complete_value(context, _, _, _, nil), do: {context, nil}

  @spec complete_value(ExecutionContext.t, %ObjectType{}, GraphQL.Document.t, any, map) :: {ExecutionContext.t, map}
  defp complete_value(context, %ObjectType{} = return_type, field_asts, _info, result) do
    {context, sub_field_asts} = collect_sub_fields(context, return_type, field_asts)
    execute_fields(context, return_type, result, sub_field_asts.fields)
  end

  defp complete_value(context, %NonNull{ofType: inner_type}, field_asts, info, result) when is_atom(inner_type) do
    complete_value(context, %NonNull{ofType: apply(inner_type, :type, [])}, field_asts, info, result)
  end

  @spec complete_value(ExecutionContext.t, %NonNull{}, GraphQL.Document.t, any, any) :: {ExecutionContext.t, map}
  defp complete_value(context, %NonNull{ofType: inner_type}, field_asts, info, result) do
    # TODO: Null Checking
    complete_value(context, inner_type, field_asts, info, result)
  end

  @spec complete_value(ExecutionContext.t, %Interface{}, GraphQL.Document.t, any, any) :: {ExecutionContext.t, map}
  defp complete_value(context, %Interface{} = return_type, field_asts, info, result) do
    runtime_type = AbstractType.get_object_type(return_type, result, info.schema)
    {context, sub_field_asts} = collect_sub_fields(context, runtime_type, field_asts)
    execute_fields(context, runtime_type, result, sub_field_asts.fields)
  end

  @spec complete_value(ExecutionContext.t, %Union{}, GraphQL.Document.t, any, any) :: {ExecutionContext.t, map}
  defp complete_value(context, %Union{} = return_type, field_asts, info, result) do
    runtime_type = AbstractType.get_object_type(return_type, result, info.schema)
    {context, sub_field_asts} = collect_sub_fields(context, runtime_type, field_asts)
    execute_fields(context, runtime_type, result, sub_field_asts.fields)
  end

  defp complete_value(context, %List{ofType: list_type}, field_asts, info, result) when is_atom(list_type) do
    complete_value(context, %List{ofType: apply(list_type, :type, [])}, field_asts, info, result)
  end

  @spec complete_value(ExecutionContext.t, %List{}, GraphQL.Document.t, any, any) :: map
  defp complete_value(context, %List{ofType: list_type}, field_asts, info, result) do
    {context, result} = Enum.reduce result, {context, []}, fn(item, {context, acc}) ->
      {context, value} = complete_value_catching_error(context, list_type, field_asts, info, item)
      {context, [value] ++ acc}
    end
    {context, Enum.reverse(result)}
  end

  defp complete_value(context, return_type, field_asts, info, result) when is_atom(return_type) do
    type = apply(return_type, :type, [])
    complete_value(context, type, field_asts, info, result)
  end

  defp complete_value(context, return_type, _field_asts, _info, result) do
    {context, GraphQL.Types.serialize(return_type, result)}
  end

  defp collect_sub_fields(context, return_type, field_asts) do
    Enum.reduce field_asts, {context, %{fields: %{}, fragments: %{}}}, fn(field_ast, {context, field_fragment_map}) ->
      if selection_set = Map.get(field_ast, :selectionSet) do
        collect_selections(context, return_type, selection_set, field_fragment_map)
      else
        {context, field_fragment_map}
      end
    end
  end

  defp field_definition(parent_type, field_name) do
    case field_name do
      :__typename -> GraphQL.Type.Introspection.meta(:typename)
      :__schema -> GraphQL.Type.Introspection.meta(:schema)
      :__type -> GraphQL.Type.Introspection.meta(:type)
      _ -> CompositeType.get_field(parent_type, field_name)
    end
  end

  defp argument_values(arg_defs, arg_asts, variable_values) do
    arg_ast_map = Enum.reduce arg_asts, %{}, fn(arg_ast, result) ->
      Map.put(result, String.to_atom(arg_ast.name.value), arg_ast)
    end
    Enum.reduce(arg_defs, %{}, fn(arg_def, result) ->
      {arg_def_name, arg_def_type} = arg_def
      value_ast = Map.get(arg_ast_map, arg_def_name, nil)

      value = value_from_ast(value_ast, arg_def_type.type, variable_values)
      value = if value, do: value, else: Map.get(arg_def_type, :defaultValue, nil)
      if value do
        Map.put(result, arg_def_name, value)
      else
        result
      end
    end)
  end

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
    [ value_from_ast(value_ast, inner_type, variable_values) ]
  end

  def value_from_ast(nil, _, _), do: nil # remove once NonNull is actually done..

  def value_from_ast(value_ast, type, variable_values) when is_atom(type) do
    value_from_ast(value_ast, apply(type, :type, []), variable_values)
  end

  def value_from_ast(value_ast, type, _) do
    GraphQL.Types.parse_literal(type, value_ast.value)
  end

  defp field_entry_key(field) do
    Map.get(field, :alias, field.name)
  end

  defp collect_fragment(context, runtime_type, selection, field_fragment_map) do
    condition_matches = typecondition_matches?(context, selection, runtime_type)
    if condition_matches do
      collect_selections(context, runtime_type, selection.selectionSet, field_fragment_map)
    else
      {context, field_fragment_map}
    end
  end

  defp typecondition_matches?(context, selection, runtime_type) do
    condition_ast = Map.get(selection, :typeCondition)
    typed_condition = GraphQL.Schema.type_from_ast(condition_ast, context.schema)

    cond do
      # no type condition was defined on this selectionset, so it's ok to run
      typed_condition == nil -> true
      # if the type condition is an interface or union, check to see if the
      # type implements the interface or belongs to the union.
      GraphQL.Type.is_abstract?(typed_condition) ->
        AbstractType.possible_type?(typed_condition, runtime_type)
      # in some cases with interfaces, the type won't be associated anywhere
      # else in the schema besides in the resolve function, which we can't
      # peek into when the typemap is generated. Because of this, the type
      # won't be found (:not_found). Before we return `false` because of that,
      # make a last check to see if the type exists after the interface's
      # resolve function has run.
      condition_ast.name.value == runtime_type.name -> true
      # the type doesn't exist, so, it can't match
      typed_condition == :not_found -> false
      # last chance to check if the type names (which are unique) match
      true -> runtime_type.name == typed_condition.name
    end
  end
end
