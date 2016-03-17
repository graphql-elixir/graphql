
# Used for computing a result as a function of the an AST traversal.  The
# traditional OO Visitor pattern does not really work well in functional
# languages due to its reliance on generating side-effects.
defmodule GraphQL.Lang.AST.Reducer do

  alias GraphQL.Lang.AST.Visitor
  alias GraphQL.Lang.AST.InitialisingVisitor
  alias GraphQL.Lang.AST.PostprocessingVisitor
  alias GraphQL.Lang.AST.Nodes

  def reduce(node, visitor, accumulator) do
    accumulator = InitialisingVisitor.init(visitor, accumulator)
    { _, accumulator } = visit(node, visitor, accumulator)
    PostprocessingVisitor.finish(visitor, accumulator)
  end

  defp visit([child|rest], visitor, accumulator) do
    { next_action, accumulator } = visit(child, visitor, accumulator)
    case next_action do
      :continue -> visit(rest, visitor, accumulator)
      :break -> { :break, accumulator }
    end
  end

  defp visit([], _visitor, accumulator), do: { :continue, accumulator }

  # FIXME: we need to enforce an invariant that if a enter is called for a node, we guarantee
  # that leave is called on a node. That means :break means "do not go deeper".
  defp visit(node, visitor, accumulator) do
    { next_action, accumulator } = Visitor.enter(visitor, node, accumulator) 
    case next_action do
      :continue ->
        { next_action, accumulator } = visit_children(node, visitor, accumulator)
        case next_action do
          :continue -> Visitor.leave(visitor, node, accumulator)
          :break -> { :break, accumulator }
        end
      :break -> { :break, accumulator }
    end
  end

  defp visit_children(node = %{kind: kind}, visitor, accumulator) when is_atom(kind) do
    children = for child_key <- Nodes.kinds[node[:kind]], Map.has_key?(node, child_key), do: node[child_key]
    visit_each_child(children, visitor, accumulator)
  end

  defp visit_each_child([child|rest], visitor, accumulator) do
    { next_action, accumulator } = visit(child, visitor, accumulator)
    case next_action do
      :continue -> visit_each_child(rest, visitor, accumulator)
      :break -> { :break, accumulator }
    end
  end

  defp visit_each_child([], _visitor, accumulator), do: { :continue, accumulator }
end
