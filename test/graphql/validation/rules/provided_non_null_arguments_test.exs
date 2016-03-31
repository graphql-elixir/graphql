

Code.require_file "../../../support/validations.exs", __DIR__

defmodule GraphQL.Validation.Rules.ProvidedNonNullArgumentsTest do
  use ExUnit.Case, async: true

  import ValidationsSupport

  alias GraphQL.Validation.Rules.ProvidedNonNullArguments, as: Rule

  test "ignores unknown arguments" do
    assert_passes_rule(
      """ 
      {
        dog {
          isHousetrained(unknownArgument: true)
        }
      }
      """,
      %Rule{}
    )
  end

  test "Arg an optional arg" do
    assert_passes_rule(
      """ 
      {
        dog {
          isHousetrained(atOtherHomes: true)
        }
      }
      """,
      %Rule{}
    )
  end

  test "No Arg an optional arg" do
    assert_passes_rule(
      """ 
      {
        dog {
          isHousetrained
        }
      }
      """,
      %Rule{}
    )
  end

  test "Multiple args" do
    assert_passes_rule(
      """ 
      {
        complicatedArgs {
          multipleReqs(req1: 1, req2: 2)
        }
      }
      """,
      %Rule{}
    )
  end

  test "Multiple args in reverse order" do
    assert_passes_rule(
      """ 
      {
        complicatedArgs {
          multipleReqs(req2: 2, req1: 1)
        }
      }
      """,
      %Rule{}
    )
  end

  test "No args on multiple optional" do
    assert_passes_rule(
      """ 
      {
        complicatedArgs {
          multipleOpts
        }
      }
      """,
      %Rule{}
    )
  end

  test "One arg on multiple optional" do
    assert_passes_rule(
      """ 
      {
        complicatedArgs {
          multipleOpts(opt1: 1)
        }
      }
      """,
      %Rule{}
    )
  end

  test "Second arg on multiple optional" do
    assert_passes_rule(
      """ 
      {
        complicatedArgs {
          multipleOpts(opt2: 1)
        }
      }
      """,
      %Rule{}
    )
  end

  test "Multiple reqs on mixedList" do
    assert_passes_rule(
      """ 
      {
        complicatedArgs {
          multipleOptAndReq(req1: 3, req2: 4)
        }
      }
      """,
      %Rule{}
    )
  end

  test "Multiple reqs and one opt on mixedList" do
    assert_passes_rule(
      """ 
      {
        complicatedArgs {
          multipleOptAndReq(req1: 3, req2: 4, opt1: 5)
        }
      }
      """,
      %Rule{}
    )
  end

  test "All reqs and opts on mixedList" do
    assert_passes_rule(
      """ 
      {
        complicatedArgs {
          multipleOptAndReq(req1: 3, req2: 4, opt1: 5, opt2: 6)
        }
      }
      """,
      %Rule{}
    )
  end

  test "Missing one non-nullable argument" do
    assert_fails_rule(
      """ 
      {
        complicatedArgs {
          multipleReqs(req2: 2)
        }
      }
      """,
      %Rule{},
      ["Field \"multipleReqs\" argument \"req1\" of type \"Int!\" is required but not provided."]
    )
  end

  test "Missing multiple non-nullable arguments" do
    assert_fails_rule(
      """ 
       {
         complicatedArgs {
           multipleReqs
         }
       }
      """,
      %Rule{},
      ["Field \"multipleReqs\" argument \"req1\" of type \"Int!\" is required but not provided.",
       "Field \"multipleReqs\" argument \"req2\" of type \"Int!\" is required but not provided."]
    )
  end

  test "Incorrect value and missing argument" do
    assert_fails_rule(
      """ 
      {
        complicatedArgs {
          multipleReqs(req1: "one")
        }
      }
      """,
      %Rule{},
      ["Field \"multipleReqs\" argument \"req2\" of type \"Int!\" is required but not provided."]
    )
  end

  @tag :skip
  test "ignores unknown directives" do
    assert_passes_rule(
      """ 
      {
        dog @unknown
      }
      """,
      %Rule{}
    )
  end

  @tag :skip
  test "with directives of valid types" do
    assert_passes_rule(
      """ 
      {
        dog @include(if: true) {
          name
        }
        human @skip(if: false) {
          name
        }
      }
      """,
      %Rule{}
    )
  end

  @tag :skip
  test "with directive with missing types" do
    assert_fails_rule(
      """ 
      {
        dog @include {
          name @skip
        }
      }
      """,
      %Rule{},
      ["Directive \"include\" argument \"if\" of type \"Boolean!\" is required but not provided.",
       "Directive \"skip\" argument \"if\" of type \"Boolean!\" is required but not provided."
      ]
    )
  end
end
