defmodule GraphQL.Mixfile do
  use Mix.Project

  @version "0.2.0"

  @description "GraphQL Elixir implementation"
  @repo_url "https://github.com/graphql-elixir/graphql"

  def project do
    [app: :graphql,
     version: @version,
     elixir: "~> 1.2",
     description: @description,
     package: package,
     source_url: @repo_url,
     homepage_url: @repo_url,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     consolidate_protocols: Mix.env == :prod,
     deps: deps,
     name: "GraphQL",
     docs: [main: "README", extras: ["README.md"]]]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:mix_test_watch, "~> 0.2", only: :dev},
      {:credo, "~> 0.3", only: :dev},
      {:dogma, "~> 0.1", only: :dev},

      # Doc dependencies
      {:earmark, "~> 0.2", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev},
      {:inch_ex, "~> 0.5", only: :dev},
      {:dialyxir, "~> 0.3", only: [:dev]},
      {:poison, "~> 1.5 or ~> 2.0", only: [:dev, :test]},
    ]
  end

  defp package do
    [maintainers: ["Josh Price", "James Sadler", "Mark Olson", "Aaron Weiker"],
     licenses: ["BSD"],
     links: %{"GitHub" => @repo_url},
     files: ~w(lib src/*.xrl src/*.yrl mix.exs *.md LICENSE)]
  end
end
