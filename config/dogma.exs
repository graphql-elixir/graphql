use Mix.Config
alias Dogma.Rule

config :dogma,

  # Select a set of rules as a base
  rule_set: Dogma.RuleSet.All,

  # Pick paths not to lint
  exclude: [
    ~r(\Atest/),
  ],

  # Override an existing rule configuration
  override: [
    %Rule.LineLength{max_length: 120},
  ]
