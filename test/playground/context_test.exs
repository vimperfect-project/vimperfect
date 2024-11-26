defmodule SessionContextTest do
  use ExUnit.Case, async: true
  alias Vimperfect.Playground.SessionContext

  setup do
    on_exit(fn -> SessionContext.delete(self()) end)
  end

  describe "get/1" do
    test "returns empty map for an empty new session" do
      assert SessionContext.get(self()) == %{}
    end

    test "returns map with all set fields" do
      SessionContext.set_field(self(), :foo, "bar")
      SessionContext.set_field(self(), :baz, "qux")
      assert SessionContext.get(self()) == %{foo: "bar", baz: "qux"}
    end
  end

  describe "set_field/3" do
    test "properly sets the field" do
      assert SessionContext.set_field(self(), :foo, "bar") == %{foo: "bar"}
    end

    test "overwrites existing field" do
      SessionContext.set_field(self(), :foo, "bar")
      assert SessionContext.set_field(self(), :foo, "baz") == %{foo: "baz"}
    end

    test "works with multiple fields" do
      assert SessionContext.set_field(self(), :foo, "bar") == %{foo: "bar"}
      assert SessionContext.set_field(self(), :baz, "qux") == %{foo: "bar", baz: "qux"}
    end

    test "works with nested fields" do
      assert SessionContext.set_field(self(), :foo, %{bar: "baz"}) == %{foo: %{bar: "baz"}}

      assert SessionContext.set_field(self(), :foo, %{bar: "baz", qux: "quux"}) == %{
               foo: %{bar: "baz", qux: "quux"}
             }
    end
  end

  describe "unset_field/2" do
    test "properly unsets the field" do
      SessionContext.set_field(self(), :foo, "bar")
      assert SessionContext.get(self()) == %{foo: "bar"}
      assert SessionContext.unset_field(self(), :foo) == %{}
    end

    test "ignores unsetting non-existent field" do
      assert SessionContext.unset_field(self(), :nope) == %{}
      SessionContext.set_field(self(), :foo, "bar")
      assert SessionContext.unset_field(self(), :nope) == %{foo: "bar"}
    end
  end

  describe "field_set?/2" do
    test "returns true if the field is set" do
      SessionContext.set_field(self(), :foo, "bar")
      assert SessionContext.field_set?(self(), :foo)
    end

    test "returns false if the field is not set" do
      assert not SessionContext.field_set?(self(), :foo)
    end
  end

  describe "delete/1" do
    test "deletes the session" do
      SessionContext.set_field(self(), :foo, "bar")
      assert SessionContext.get(self()) == %{foo: "bar"}
      assert :ok = SessionContext.delete(self())
      assert SessionContext.get(self()) == %{}
    end

    test "ignores deletes for non-existent sessions" do
      assert :ok = SessionContext.delete(self())
      assert SessionContext.get(self()) == %{}
    end
  end
end
