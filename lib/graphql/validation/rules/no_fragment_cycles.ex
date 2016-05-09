defmodule GraphQL.Validation.Rules.NoFragmentCycles do

  alias GraphQL.Lang.AST.{Visitor, InitialisingVisitor, DocumentInfo}
  alias GraphQL.Util.Stack
  import GraphQL.Validation

  defstruct name: "NoFragmentCycles"

  defimpl InitialisingVisitor do
    def init(_visitor, acc) do
      Map.merge(acc, %{
        visited_fragments: %{},
        spread_path: %Stack{},
        spread_path_indices: %{}
      })
    end
  end

  defimpl Visitor do
    def enter(_visitor, %{kind: :FragmentDefinition} = node, acc) do
      if !visited?(acc, node) do
        {:continue, detect_cycles(acc, node)}
      else
        {:continue, acc}
      end
    end

    def enter(_visitor, _node, acc) do
      {:continue, acc}
    end

    def leave(_visitor, _node, acc) do
      {:continue, acc}
    end

    defp detect_cycles(acc, fragment_def) do
      acc
      |> mark_visited(fragment_def)
      |> detect_cycles_via_spread_nodes(fragment_def, spread_nodes_of_fragment(fragment_def))
    end

    defp detect_cycles_via_spread_nodes(acc, _, []), do: acc
    defp detect_cycles_via_spread_nodes(acc, fragment_def, spread_nodes) do
      frag_name = fragment_def.name.value
      acc = %{ acc | spread_path_indices:
        Map.merge(acc[:spread_path_indices], %{frag_name => Stack.length(acc[:spread_path])})}

      acc = process_spread_nodes(acc, spread_nodes)

      %{ acc | spread_path_indices: Map.delete(acc[:spread_path_indices], frag_name)}
    end

    defp process_spread_nodes(acc, []), do: acc
    defp process_spread_nodes(acc, [spread_node|rest]) do
      spread_name = spread_node.name.value
      cycle_index = Map.get(acc[:spread_path_indices], spread_name, nil)
      process_spread_nodes(process_one_node(acc, spread_node, cycle_index), rest)
    end

    defp process_one_node(acc, spread_node, cycle_index) when is_integer(cycle_index) do
      cycle_path = Enum.slice(
        Enum.reverse(acc[:spread_path].elements),
        cycle_index,
        Stack.length(acc[:spread_path])
      )
      report_error(acc, cycle_error_message(spread_node.name.value, Enum.map(cycle_path, fn(s) -> s.name.value end)))
    end

    defp process_one_node(acc, spread_node, _) do
      acc = %{ acc | spread_path: Stack.push(acc[:spread_path], spread_node)} 
      if !visited?(acc, spread_node) do
        spread_fragment = DocumentInfo.get_fragment_definition(acc[:document_info], spread_node.name.value)
        if spread_fragment do
          acc = detect_cycles(acc, spread_fragment)
        end
      end
      %{ acc | spread_path: Stack.pop(acc[:spread_path])} 
    end

    defp visited?(acc, node) do
      Map.has_key?(acc[:visited_fragments], node.name.value)
    end

    defp mark_visited(acc, node) do
      %{acc | visited_fragments:
        Map.merge(acc[:visited_fragments], %{node.name.value => true})}
    end

    defp cycle_error_message(frag_name, spread_names) do
      via = case length(spread_names) do
        0 -> ""
        _ -> " via #{Enum.join(spread_names, ", ")}"
      end
      "Cannot spread fragment #{frag_name} within itself#{via}."
    end

    defp spread_nodes_of_fragment(fragment_def) do
      spread_nodes_of_selection_sets([fragment_def.selectionSet])
    end

    defp spread_nodes_of_selection_sets([]), do: []
    defp spread_nodes_of_selection_sets([selection_set|rest]) do
      spread_nodes_of_selections(selection_set.selections) ++ spread_nodes_of_selection_sets(rest)
    end

    defp spread_nodes_of_selections([]), do: []
    defp spread_nodes_of_selections([%{kind: :FragmentSpread} = selection|rest]) do
      [selection] ++ spread_nodes_of_selections(rest)
    end
    defp spread_nodes_of_selections([%{selectionSet: selection_set}|rest]) do
      spread_nodes_of_selection_sets([selection_set]) ++ spread_nodes_of_selections(rest)
    end
    defp spread_nodes_of_selections([_|rest]) do
      spread_nodes_of_selections(rest)
    end
  end
end
