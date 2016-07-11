
defmodule GraphQL.Execution.Selection do

  alias GraphQL.Execution.FieldResolver
  alias GraphQL.Execution.Types
  alias GraphQL.Execution.Directives
  alias GraphQL.Type.AbstractType

  @spec execute_fields_serially(ExecutionContext.t, atom, map, any) :: {ExecutionContext.t, map}
  def execute_fields_serially(context, parent_type, source_value, fields) do
    # call execute_fields because no async operations yet
    execute_fields(context, parent_type, source_value, fields)
  end

  @spec execute_fields(ExecutionContext.t, atom | Map, any, any) :: {ExecutionContext.t, map}
  def execute_fields(context, parent_type, source_value, fields) do
    Enum.reduce fields, {context, %{}}, fn({field_name_ast, field_asts}, {context, results}) ->
      FieldResolver.resolve_field(context, Types.unwrap_type(parent_type), source_value, field_asts)
      |> unwrap_result(results, field_name_ast)
    end
  end

  def complete_sub_fields(return_type, context, field_asts, result) do
    {context, sub_field_asts} = collect_sub_fields(context, return_type, field_asts)
    execute_fields(context, return_type, result, sub_field_asts.fields)
  end

  def collect_sub_fields(context, return_type, field_asts) do
    Enum.reduce field_asts, {context, %{fields: %{}, fragments: %{}}}, fn(field_ast, {context, field_fragment_map}) ->
      if selection_set = Map.get(field_ast, :selectionSet) do
        collect_selections(context, return_type, selection_set, field_fragment_map)
      else
        {context, field_fragment_map}
      end
    end
  end

  def collect_selections(context, runtime_type, selection_set, field_fragment_map \\ %{fields: %{}, fragments: %{}}) do
    Enum.reduce selection_set[:selections], {context, field_fragment_map}, fn(selection, {context, field_fragment_map}) ->
      collect_selection(context, runtime_type, selection, field_fragment_map)
    end
  end

  def collect_selection(context, _, %{kind: :Field} = selection, field_fragment_map) do
    if include_node?(context, selection[:directives]) do
      field_name = field_entry_key(selection)
      fields = field_fragment_map.fields[field_name] || []
      {context, put_in(field_fragment_map.fields[field_name], [selection | fields])}
    else
      {context, field_fragment_map}
    end
  end

  def collect_selection(context, runtime_type, %{kind: :InlineFragment} = selection, field_fragment_map) do
    if include_node?(context, selection[:directives]) do
      collect_fragment(context, runtime_type, selection, field_fragment_map)
    else
      {context, field_fragment_map}
    end
  end

  def collect_selection(context, runtime_type, %{kind: :FragmentSpread} = selection, field_fragment_map) do
    fragment_name = selection.name.value
    if include_node?(context, selection[:directives]) do
      if !field_fragment_map.fragments[fragment_name] do
        field_fragment_map = put_in(field_fragment_map.fragments[fragment_name], true)
        collect_fragment(context, runtime_type, context.fragments[fragment_name], field_fragment_map)
      else
        {context, field_fragment_map}
      end
    else
      {context, field_fragment_map}
    end
  end

  def collect_selection(context, _, _, field_fragment_map), do: {context, field_fragment_map}

  def collect_fragment(context, runtime_type, selection, field_fragment_map) do
    condition_matches = typecondition_matches?(context, selection, runtime_type)
    if condition_matches do
      collect_selections(context, runtime_type, selection.selectionSet, field_fragment_map)
    else
      {context, field_fragment_map}
    end
  end

  defp unwrap_result({context, :undefined}, results, _), do: {context, results}
  defp unwrap_result({context, value}, results, field_name_ast) do
    {context, Map.put(results, field_name_ast.value, value)}
  end

  defp include_node?(_context, nil), do: true
  defp include_node?(context, directives) do
    Directives.resolve_directive(context, directives, :include) &&
    !Directives.resolve_directive(context, directives, :skip)
  end

  defp field_entry_key(field) do
    Map.get(field, :alias, field.name)
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
