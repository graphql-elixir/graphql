defmodule GraphQL.Lang.Visitor do
  defmodule Node do
    @kinds %{
      Name: [],
      Document: [:definitions],
      OperationDefinition: [:name, :variableDefinitions, :directives, :selectionSet],
      VariableDefinition: [:variable, :type, :defaultValue],
      Variable: [:name],
      SelectionSet: [:selections],
      Field: [:alias, :name, :arguments, :directives, :selectionSet],
      Argument: [:name, :value],
      FragmentSpread: [:name, :directives],
      InlineFragment: [:typeCondition, :directives, :selectionSet],
      FragmentDefinition: [:name, :typeCondition, :directives, :selectionSet],
      IntValue: [],
      FloatValue: [],
      StringValue: [],
      BooleanValue: [],
      EnumValue: [],
      ListValue: [:values],
      ObjectValue: [:fields],
      ObjectField: [:name, :value],
      Directive: [:name, :arguments],
      NamedType: [:name],
      ListType: [:type],
      NonNullType: [:type],
      ObjectTypeDefinition: [:name, :interfaces, :fields],
      FieldDefinition: [:name, :arguments, :type],
      InputValueDefinition: [:name, :type, :defaultValue],
      InterfaceTypeDefinition: [:name, :fields],
      UnionTypeDefinition: [:name, :types],
      ScalarTypeDefinition: [:name],
      EnumTypeDefinition: [:name, :values],
      EnumValueDefinition: [:name],
      InputObjectTypeDefinition: [:name, :fields],
      TypeExtensionDefinition: [:definition]
    }

    def children(item) when is_map(item),  do: Dict.get(@kinds, item.kind, [])
    def children(item) when is_list(item), do: item
    def children(_),                       do: []
  end

  defmodule Stack do
    defstruct ancestors: [],
              in_list: false,
              index: -1,
              key: nil,
              keys: [],
              parent: nil,
              path: [],
              previous: nil
  end

  # Depth-first traversal through the tree.
  def visit(entrypoint, visitors) when is_map(visitors) do
    context = %{entrypoint: entrypoint, visitors: visitors}
    stack = %Stack{keys: Node.children(entrypoint), in_list: is_list(entrypoint)}

    case walk(stack, context) do
      {:ok, result} -> {:ok, result}
    end
  end

  defp walk(_stack = nil, context), do: {:ok, context.entrypoint}
  defp walk(stack = %Stack{}, context) do
    stack = %Stack{stack | index: stack.index + 1}
    is_leaving = leaving?(stack)

    {item, stack} = case is_leaving do
      false -> enter_node(stack, context.entrypoint)
      true  -> leave_node(stack)
    end

    apply_visitors(item, is_leaving, stack, context.visitors)
    walk(next_node(is_leaving, item, stack), context)
  end

  defp leaving?(stack), do: stack.index === length(stack.keys)

  defp next_node(true, _, stack), do: stack
  defp next_node(_, nil, stack), do: stack
  defp next_node(false, item, stack) when is_nil(item), do: stack
  defp next_node(false, item, stack) do
    ancestors = cond do
      stack.parent -> stack.ancestors ++ [stack.parent]
      true         -> stack.ancestors
    end

    %Stack{stack |
      parent: item,
      keys: Node.children(item),
      in_list: is_list(item),
      index: -1,
      previous: stack,
      ancestors: ancestors
    }
  end

  defp enter_node(stack, entrypoint) do
    %{parent: parent, in_list: in_list, keys: keys, index: index} = stack

    {item, key} = cond do
      not is_nil(parent) and in_list     -> {Enum.at(parent, index), index}
      not is_nil(parent) and not in_list -> {Dict.get(parent, Enum.at(keys, index)), Enum.at(keys, index)}
      is_nil(parent)                     -> {entrypoint, nil}
      true                               -> {nil, nil}
    end

    path = cond do
      parent && !is_nil(item) -> stack.path ++ [key]
      true                    -> stack.path
    end

    {item, %Stack{stack | key: key, path: path}}
  end

  defp leave_node(_stack = %Stack{previous: nil}), do: {nil, nil}
  defp leave_node(stack) do
    %{ancestors: ancestors} = stack

    {parent, ancestors} = cond do
      length(ancestors) === 0 -> {nil, []}
      true                    -> {List.last(ancestors), Enum.drop(ancestors, -1)}
    end

    {stack.parent, %Stack{stack |
      key: List.last(stack.path),
      path: Enum.drop(stack.path, -1),
      parent: parent,
      ancestors: ancestors,
      index: stack.previous.index,
      keys: stack.previous.keys,
      in_list: stack.previous.in_list,
      previous: stack.previous.previous
    }}
  end

  defp apply_visitors(nil, _, _, _), do: nil
  defp apply_visitors(item, is_leaving, stack, visitors) do
    cond do
      not is_list(item) and not is_item(item) -> throw "Invalid AST Node: #{inspect(item)}"
      is_list(item) -> nil
      true ->
        case get_visitor(visitors, item.kind, is_leaving) do
          {type, visitor} ->
            args = stack |> Map.take([:key, :parent, :path, :ancestors]) |> Map.merge(%{item: item})
            case visitor.(args) do
              %{item: action} -> edit(type, action, item)
              _               -> nil
            end
          nil -> nil
        end
    end
  end

  defp get_visitor(visitors, kind, true),  do: get_visitor(visitors, kind, :leave)
  defp get_visitor(visitors, kind, false), do: get_visitor(visitors, kind, :enter)
  defp get_visitor(visitors, kind, type) do
    # TODO: this is pretty gross
    cond do
      Map.has_key?(visitors, kind) ->
        name_key = Map.get(visitors, kind)
        cond do
          is_map(name_key)                            -> {type, Map.get(name_key, type)}  # %{Kind: type: fn()}
          is_function(name_key, 1) and type == :enter -> {type, name_key} # %{Kind: fn()}
          true -> nil
        end
      Map.has_key?(visitors, type) -> {type, get_in(visitors, [type])} # %{type: fn()}
      true -> nil
    end
  end

  defp is_item(item) do
    is_map(item) and Map.has_key?(item, :kind) and is_atom(item.kind)
  end

  defp edit(type, action, item) when is_atom(type) and is_map(item), do: edit(type, action, item)
  defp edit(:enter, :skip, _item), do: nil                                 # don't visit this item
  defp edit(:enter, :delete, _item), do: nil                               # delete the item
  defp edit(:enter, replacement, _item) when is_map(replacement), do: nil  # replace the item
  defp edit(:leave, :delete, _item), do: nil                               # delete the item
  defp edit(:leave, replacement, _item) when is_map(replacement), do: nil  # replace the item
end
