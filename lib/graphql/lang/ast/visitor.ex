
defmodule GraphQL.Lang.AST do
  defprotocol Visitor do
    @moduledoc """
    Implementations of Visitor are used by the ASTReducer to transform a GraphQL AST
    into an arbitrary value.

    The value can be the result of validations, or a transformation of the AST into
    a new AST, for example.

    The fallback implementations of 'enter' and 'leave' return the accumulator untouched.
    """

    @fallback_to_any true

    @doc """
    Called when entering a node of the AST.

    The return value should be:

    {next_action, acc}

    where next_action is either :break or :continue and acc is the new value of the accumulator.

    :break will abort the visitor and AST traversal will cease returning the current value of the accumulator.
    """
    def enter(visitor, node, accumulator)

    @doc """
    Called when leaving a node of the AST.

    The return value should be:

    {next_action, acc}

    where next_action is either :break or :continue and acc is the new value of the accumulator.

    :break will abort the visitor and AST traversal will cease returning the current value of the accumulator.
    """
    def leave(visitor, node, accumulator)
  end

  defimpl Visitor, for: Any do
    def enter(_visitor, _node, accumulator), do: {:continue, accumulator}
    def leave(_visitor, _node, accumulator), do: {:continue, accumulator}
  end

  defprotocol InitialisingVisitor do
    @moduledoc """
    A Visitor that implements this protocol will have the opportunity to perform some
    initialisation and set up the accumulator before AST traversal is started.

    The fallback implementation returns the accumulator untouched.
    """

    @fallback_to_any true

    @doc """
    Invoked before traversal begins.  The Visitor can do any once-off accumulator initialisation here.
    """
    def init(visitor, accumulator)
  end

  defprotocol PostprocessingVisitor do
    @moduledoc """
    A Visitor that implements this protocol will have the opportunity to transform
    the accumulator into something more consumer friendly. It can often be the case that
    the working form of the accumulator is not what should be returned from ASTReducer.reduce/3.

    This also means that the accumulator (always a Map) can be transformed into an
    arbitrary struct or other Erlang/Elixir type.

    The fallback implementation returns the accumulator untouched.
    """

    @fallback_to_any true

    @doc """
    Invoked once after traversal ends.  This can be used to transform the accumulator
    into an arbitrary value.
    """
    def finish(visitor, accumulator)
  end

  defimpl InitialisingVisitor, for: Any do
    def init(_visitor, accumulator), do: accumulator
  end

  defimpl PostprocessingVisitor, for: Any do
    def finish(_visitor, accumulator), do: accumulator
  end
end
