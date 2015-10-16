defmodule GraphQL.Mixfile do
  use Mix.Project

  def project do
    [app: :graphql,
     name: "GraphQL",
     version: "0.0.3",
     elixir: "~> 1.0",
     description: description,
     package: package,
     source_url: "https://github.com/joshprice/graphql-elixir",
     homepage_url: "https://github.com/joshprice/graphql-elixir",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     docs: [extras: ["README.md"]]]
  end

  defp description do
    """
    An Elixir implementation of GraphQL
    """
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:poison, "~> 1.5.0"},
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.8", only: :dev},
      {:mix_test_watch, "~> 0.2", only: :dev},
      {:inch_ex, only: :docs}
    ]
  end

  defp package do
    [# These are the default files included in the package
     files: ["lib", "src/*.xrl", "src/*.yrl", "mix.exs", "README*", "LICENSE*"],
     maintainers: ["Josh Price", "James Sadler"],
     licenses: ["BSD"],
     links: %{"GitHub" => "https://github.com/joshprice/graphql-elixir"}]
  end

end
