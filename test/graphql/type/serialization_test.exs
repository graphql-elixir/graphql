defmodule GraphQL.Lang.Type.SerializationTest do
  use ExUnit.Case, async: true
  import GraphQL.Types

  test "serializes output int" do
    assert 1   == serialize(%GraphQL.Type.Int{}, 1)
    assert 0   == serialize(%GraphQL.Type.Int{}, 0)
    assert -1  == serialize(%GraphQL.Type.Int{}, -1)
    assert 0   == serialize(%GraphQL.Type.Int{}, 0.1)
    assert 1   == serialize(%GraphQL.Type.Int{}, 1.1)
    assert -1  == serialize(%GraphQL.Type.Int{}, -1.1)
    assert 100 == serialize(%GraphQL.Type.Int{}, 1.0e2)
    assert nil == serialize(%GraphQL.Type.Int{}, 9876504321)
    assert nil == serialize(%GraphQL.Type.Int{}, -9876504321)
    assert nil == serialize(%GraphQL.Type.Int{}, 1.0e100)
    assert nil == serialize(%GraphQL.Type.Int{}, -1.0e100)
    assert -1  == serialize(%GraphQL.Type.Int{}, "-1.1")
    assert nil == serialize(%GraphQL.Type.Int{}, "one")
    assert 0   == serialize(%GraphQL.Type.Int{}, false)
    assert 1   == serialize(%GraphQL.Type.Int{}, true)
  end

  test "serializes output float" do
    assert 1.0  == serialize(%GraphQL.Type.Float{}, 1)
    assert 0.0  == serialize(%GraphQL.Type.Float{}, 0)
    assert -1.0 == serialize(%GraphQL.Type.Float{}, -1)
    assert 0.1  == serialize(%GraphQL.Type.Float{}, 0.1)
    assert 1.1  == serialize(%GraphQL.Type.Float{}, 1.1)
    assert -1.1 == serialize(%GraphQL.Type.Float{}, -1.1)
    assert -1.1 == serialize(%GraphQL.Type.Float{}, "-1.1")
    assert nil  == serialize(%GraphQL.Type.Float{}, "one")
    assert 0.0  == serialize(%GraphQL.Type.Float{}, false)
    assert 1.0  == serialize(%GraphQL.Type.Float{}, true)
  end

  test "serializes output strings" do
    assert "string" == serialize(%GraphQL.Type.String{}, "string")
    assert "1"      == serialize(%GraphQL.Type.String{}, 1)
    assert "-1.1"   == serialize(%GraphQL.Type.String{}, -1.1)
    assert "true"   == serialize(%GraphQL.Type.String{}, true)
    assert "false"  == serialize(%GraphQL.Type.String{}, false)
  end

  test "serializes output boolean" do
    assert true  == serialize(%GraphQL.Type.Boolean{}, "string")
    assert false == serialize(%GraphQL.Type.Boolean{}, "")
    assert true  == serialize(%GraphQL.Type.Boolean{}, 1)
    assert false == serialize(%GraphQL.Type.Boolean{}, 0)
    assert true  == serialize(%GraphQL.Type.Boolean{}, true)
    assert false == serialize(%GraphQL.Type.Boolean{}, false)
  end
end
