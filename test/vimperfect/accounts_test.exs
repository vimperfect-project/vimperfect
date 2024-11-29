defmodule Vimperfect.AccountsTest do
  use Vimperfect.DataCase, async: true

  alias Vimperfect.Accounts
  alias Vimperfect.Accounts.User

  import Vimperfect.AccountsFixtures

  describe "find_or_create_user/1" do
    test "creates a user" do
      attrs = %{username: "bob", provider: :github, email: "email@example.com"}
      assert {:ok, %User{}} = Accounts.find_or_create_user(attrs)
    end

    test "returns an error when the user already exists" do
      fixture = user_fixture()
      assert {:ok, %User{} = user2} = Accounts.find_or_create_user(fixture)
      assert fixture.id == user2.id
    end
  end

  describe "update_user/1" do
    test "updates the user" do
      fixture = user_fixture()
      assert {:ok, user} = Accounts.update_user(fixture, %{username: "new_username"})
      assert user.username == "new_username"
    end

    test "handles invalid attrs" do
      fixture = user_fixture()

      assert {:error,
              %Ecto.Changeset{errors: [username: {"can't be blank", [validation: :required]}]}} =
               Accounts.update_user(fixture, %{username: nil})

      assert {:error,
              %Ecto.Changeset{errors: [email: {"is not a valid email", [validation: :email]}]}} =
               Accounts.update_user(fixture, %{email: "non-email"})
    end
  end
end
