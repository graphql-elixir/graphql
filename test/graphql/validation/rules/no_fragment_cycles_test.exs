
Code.require_file "../../../support/validations.exs", __DIR__

defmodule GraphQL.Validation.Rules.NoFragmentCyclesTest do
  use ExUnit.Case, async: true

  import ValidationsSupport

  alias GraphQL.Validation.Rules.NoFragmentCycles, as: Rule

  test "single reference is valid" do
    assert_passes_rule(
      """ 
      fragment fragA on Dog { ...fragB }
      fragment fragB on Dog { name }
      """,
      %Rule{}
    )
  end

  test "spreading twice is not circular" do
    assert_passes_rule(
      """ 
      fragment fragA on Dog { ...fragB, ...fragB }
      fragment fragB on Dog { name }
      """,
      %Rule{}
    )
  end

  test "spreading twice indirectly is not circular" do
    assert_passes_rule(
      """ 
      fragment fragA on Dog { ...fragB, ...fragC }
      fragment fragB on Dog { ...fragC }
      fragment fragC on Dog { name }
      """,
      %Rule{}
    )
  end

  test "double spread within abstract types" do
    assert_passes_rule(
      """ 
      fragment nameFragment on Pet {
        ... on Dog { name }
        ... on Cat { name }
      }

      fragment spreadsInAnon on Pet {
        ... on Dog { ...nameFragment }
        ... on Cat { ...nameFragment }
      }
      """,
      %Rule{}
    )
  end

  test "does not false positive on unknown fragment" do
    assert_passes_rule(
      """ 
      fragment nameFragment on Pet {
        ...UnknownFragment
      }
      """,
      %Rule{}
    )
  end

  test "spreading recursively within field fails" do
    assert_fails_rule(
      """ 
      fragment fragA on Human { relatives { ...fragA } }
      """,
      %Rule{},
      ["Cannot spread fragment fragA within itself."]
    )
  end

  test "no spreading itself directly" do
    assert_fails_rule(
      """ 
      fragment fragA on Dog { ...fragA }
      """,
      %Rule{},
      ["Cannot spread fragment fragA within itself."]
    )
  end

  test "no spreading itself directly within inline fragment" do
    assert_fails_rule(
      """ 
      fragment fragA on Pet {
        ... on Dog {
          ...fragA
        }
      }
      """,
      %Rule{},
      ["Cannot spread fragment fragA within itself."]
    )
  end

  test "no spreading itself indirectly" do
    assert_fails_rule(
      """ 
      fragment fragA on Dog { ...fragB }
      fragment fragB on Dog { ...fragA }
      """,
      %Rule{},
      ["Cannot spread fragment fragA within itself via fragB."]
    )
  end

  test "no spreading itself indirectly reports opposite order" do
    assert_fails_rule(
      """ 
      fragment fragB on Dog { ...fragA }
      fragment fragA on Dog { ...fragB }
      """,
      %Rule{},
      ["Cannot spread fragment fragB within itself via fragA."]
    )
  end

  test "no spreading itself indirectly within inline fragment" do
    assert_fails_rule(
      """ 
      fragment fragA on Pet {
        ... on Dog {
          ...fragB
        }
      }
      fragment fragB on Pet {
        ... on Dog {
          ...fragA
        }
      }
      """,
      %Rule{},
      ["Cannot spread fragment fragA within itself via fragB."]
    )
  end

  test "no spreading itself deeply" do
    assert_fails_rule(
      """ 
      fragment fragA on Dog { ...fragB }
      fragment fragB on Dog { ...fragC }
      fragment fragC on Dog { ...fragO }
      fragment fragX on Dog { ...fragY }
      fragment fragY on Dog { ...fragZ }
      fragment fragZ on Dog { ...fragO }
      fragment fragO on Dog { ...fragP }
      fragment fragP on Dog { ...fragA, ...fragX }
      """,
      %Rule{},
      ["Cannot spread fragment fragA within itself via fragB, fragC, fragO, fragP.",
       "Cannot spread fragment fragO within itself via fragP, fragX, fragY, fragZ."]
    )
  end

  test "no spreading itself deeply two paths" do
    assert_fails_rule(
      """ 
      fragment fragA on Dog { ...fragB, ...fragC }
      fragment fragB on Dog { ...fragA }
      fragment fragC on Dog { ...fragA }
      """,
      %Rule{},
      ["Cannot spread fragment fragA within itself via fragB.",
       "Cannot spread fragment fragA within itself via fragC."]
    )
  end

  test "no spreading itself deeply two paths -- alt traverse order" do
    assert_fails_rule(
      """ 
      fragment fragA on Dog { ...fragC }
      fragment fragB on Dog { ...fragC }
      fragment fragC on Dog { ...fragA, ...fragB }
      """,
      %Rule{},
      ["Cannot spread fragment fragA within itself via fragC.",
       "Cannot spread fragment fragC within itself via fragB."]
    )
  end

  test "no spreading itself deeply and immediately" do
    assert_fails_rule(
      """ 
      fragment fragA on Dog { ...fragB }
      fragment fragB on Dog { ...fragB, ...fragC }
      fragment fragC on Dog { ...fragA, ...fragB }
      """,
      %Rule{},
      ["Cannot spread fragment fragB within itself.",
       "Cannot spread fragment fragA within itself via fragB, fragC.",
       "Cannot spread fragment fragB within itself via fragC."]
    )
  end
end
