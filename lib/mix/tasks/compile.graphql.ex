defmodule Mix.Tasks.Compile.Graphql do
  use Mix.Task

  @recursive true
  @manifest ".compile.graphql"

  @moduledoc """
  Compiles `.graphql` files which have changed since the last generation.

  Currently only handles schema files, but will support queries in future.

  To use this you need to add the `:graphql` compiler to the front ofyour compiler chain.
  This just needs to be anywhere before the Elixir compiler because we are
  generating Elixir code.

  In your `mix.exs` project in a Phoenix project for example:

      compilers: [:phoenix, :graphql] ++ Mix.compilers

  You also need to tell the GraphQL compiler which files to pick up.

  In `config/config.exs`

      config :graphql, source_path: "web/graphql/**/*_schema.graphql"


  ## Command line options

    * `--force` - forces compilation regardless of modification times

  """

  @spec run(OptionParser.argv) :: :ok | :noop
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [force: :boolean])

    graphql_schema_glob = Application.get_env(:graphql, :source_path)

    changed =
      graphql_schema_glob
      |> Path.wildcard
      |> compile_all(opts)

    if Enum.any?(changed, &(&1 == :ok)) do
      :ok
    else
      :noop
    end
  end

  @doc """
  Returns GraphQL manifests.
  """
  def manifests, do: [manifest]
  defp manifest, do: Path.join(Mix.Project.manifest_path, @manifest)

  def compile_all(schema_paths, opts) do
    Enum.map schema_paths, &(compile(&1, opts))
  end

  def compile(schema_path, opts) do
    base_filename = extract_file_prefix(schema_path)
    target = base_filename <> ".ex"
    if opts[:force] || Mix.Utils.stale?([schema_path], [target]) do
      Mix.shell.info "Compiling `#{schema_path}` to `#{target}`"
      with target,
           {:ok, source_schema}    <- File.read(schema_path),
           {:ok, generated_schema} <- GraphQL.Schema.Generator.generate(base_filename, source_schema),
        do: File.write!(target, generated_schema)
    else
      Mix.shell.info "Skipping `#{schema_path}`"
    end
  end

  def extract_file_prefix(path) do
    Path.join(Path.dirname(path), Path.basename(path, ".graphql"))
  end
end
