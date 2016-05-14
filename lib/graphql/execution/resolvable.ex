
defprotocol GraphQL.Execution.Resolvable do
  @fallback_to_any true

  def resolve(resolvable, source, args, context, info)
end

defmodule GraphQL.Execution.ResolveWrapper do
  def wrap(fun) do
    try do
      {:ok, fun.()}
    rescue
      e in RuntimeError -> {:error, e.message}
    end
  end
end

alias GraphQL.Execution.ResolveWrapper

defimpl GraphQL.Execution.Resolvable, for: Function do
  def resolve(fun, source, args, context, info) do
    ResolveWrapper.wrap fn() ->
      fun.(source, args, context, info)
    end
  end
end

defimpl GraphQL.Execution.Resolvable, for: Tuple  do
  def resolve({mod, fun}, source, args, context, info),    do: do_resolve(mod, fun, source, args, context, info)
  def resolve({mod, fun, _}, source, args, context, info), do: do_resolve(mod, fun, source, args, context, info)

  defp do_resolve(mod, fun, source, args, context, info) do
    ResolveWrapper.wrap fn() ->
      apply(mod, fun, [source, args, context, info])
    end
  end
end

defimpl GraphQL.Execution.Resolvable, for: Atom  do
  def resolve(nil, source, _args, context, info) do
    # NOTE: data keys and field names should be normalized to strings when we load the schema
    # and then we wouldn't need this Atom or String logic.
    {:ok, Map.get(source, info.field_name, Map.get(source, Atom.to_string(info.field_name)))}
  end
end

defimpl GraphQL.Execution.Resolvable, for: Any  do
  def resolve(resolution, _source, _args, _context, _info), do: {:ok, resolution}
end
