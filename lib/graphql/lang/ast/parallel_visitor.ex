
defmodule GraphQL.Lang.AST.ParallelVisitor do
  @moduledoc ~S"""
  A ParallelVisitor runs all child visitors in parallel instead of serially like the CompositeVisitor.

  In this context, 'in parallel' really means that for each node in the AST, each visitor will be invoked
  for each node in the AST, but the :break/:continue return value of enter and leave is maintained per-visitor.

  This means invividual visitors can bail out of AST processing as soon as possible and not waste cycles.

  This code based on the graphql-js *visitInParallel* function.
  """

  alias GraphQL.Lang.AST.Visitor
  alias GraphQL.Lang.AST.InitialisingVisitor
  alias GraphQL.Lang.AST.PostprocessingVisitor

  defstruct visitors: []
  
  defimpl Visitor do
    def enter(visitor, node, accumulator) do
      visitors = Enum.filter(visitor.visitors, fn(child_visitor) ->
        !skipping?(accumulator, child_visitor)
      end)
      accumulator = Enum.reduce(visitors, accumulator, fn(child_visitor, accumulator) ->
        case child_visitor |> Visitor.enter(node, accumulator) do
          {:continue, next_accumulator} -> next_accumulator
          {:break, next_accumulator} ->
            put_in(next_accumulator[:skipping][child_visitor], node)
        end
      end)
      {:continue, accumulator}
    end

    def leave(visitor, node, accumulator) do
      accumulator = Enum.reduce(visitor.visitors, accumulator, fn(child_visitor, acc) ->
        cond do
          !skipping?(acc, child_visitor) ->
            {_, next_accumulator} = child_visitor |> Visitor.leave(node, acc)
            next_accumulator
          accumulator[:skipping][child_visitor] == node ->
            put_in(acc[:skipping][child_visitor], false)
          true -> accumulator
        end
      end)
      {:continue, accumulator}
    end

    defp skipping?(accumulator, child_visitor) do
      Map.has_key?(accumulator[:skipping], child_visitor)
    end
  end

  defimpl InitialisingVisitor do
    def init(visitor, accumulator) do
      accumulator = put_in(accumulator[:skipping], %{})
      Enum.reduce(visitor.visitors, accumulator, &InitialisingVisitor.init/2)
    end
  end

  defimpl PostprocessingVisitor do
    def finish(visitor, accumulator) do
      Enum.reduce(visitor.visitors, accumulator, &PostprocessingVisitor.finish/2)
    end
  end

end
