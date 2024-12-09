defmodule VimperfectWeb.ProfileLiveTest do
  use VimperfectWeb.ConnCase

  import Phoenix.LiveViewTest
  import Vimperfect.AccountsFixtures

  @create_attrs %{
    key:
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINyizBzsyvs5KYsyKdTgcpbw52tpEPmfl1q3m9VD5+V7 user@vimperfect"
  }
  @invalid_attrs %{
    key: "I'm not an expert but this is not an ssh key"
  }
  @empty_attrs %{
    key: ""
  }

  defp create_user(%{conn: conn}) do
    user = user_fixture()
    conn = Plug.Test.init_test_session(conn, %{user_id: user.id})
    %{user: user, conn: conn}
  end

  describe "Index" do
    setup [:create_user]

    test "shows the profile settings page with no keys", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/profile")

      assert html =~ "Profile settings"
      assert html =~ "No public keys added yet."
    end

    test "shows available public keys", %{conn: conn, user: user} do
      # Add the key for the user first
      add_public_key_fixture(user)

      {:ok, _index_live, html} = live(conn, ~p"/profile")

      assert html =~ "Key 1"
    end

    test "saves a valid public key", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/profile")

      assert index_live
             |> form("#public-key-form", public_key: @create_attrs)
             |> render_submit()

      {path, flash} = assert_redirect(index_live)

      assert path == ~p"/profile"
      assert flash["info"] == "Key has been added successfully."
    end

    test "does not let a user to save the same key twice", %{conn: conn, user: user} do
      public_key = add_public_key_fixture(user).public_keys |> List.first()

      {:ok, index_live, _html} = live(conn, ~p"/profile")

      assert index_live
             |> form("#public-key-form", public_key: %{key: public_key.key})
             |> render_submit()

      html = render(index_live)
      assert String.contains?(html, "Key 2") == false
      assert html =~ "this key is already used"
    end

    test "validates invalid public key", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/profile")

      assert index_live
             |> form("#public-key-form", public_key: @invalid_attrs)
             |> render_submit()

      html = render(index_live)
      assert html =~ "not a valid public key"
    end

    test "validates empty public key", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/profile")

      assert index_live
             |> form("#public-key-form", public_key: @empty_attrs)
             |> render_submit()

      html = render(index_live)
      assert html =~ "can&#39;t be blank"
    end

    #     assert_patch(index_live, ~p"/profile/new")

    #     assert index_live
    #            |> form("#profile-form", profile: @invalid_attrs)
    #            |> render_change() =~ "can&#39;t be blank"

    #     html = render(index_live)
    #     assert html =~ "Profile created successfully"
    #   end

    #   test "updates profile in listing", %{conn: conn, profile: profile} do
    #     {:ok, index_live, _html} = live(conn, ~p"/profile")

    #     assert index_live |> element("#profile-#{profile.id} a", "Edit") |> render_click() =~
    #              "Edit Profile"

    #     assert_patch(index_live, ~p"/profile/#{profile}/edit")

    #     assert index_live
    #            |> form("#profile-form", profile: @invalid_attrs)
    #            |> render_change() =~ "can&#39;t be blank"

    #     assert index_live
    #            |> form("#profile-form", profile: @update_attrs)
    #            |> render_submit()

    #     assert_patch(index_live, ~p"/profile")

    #     html = render(index_live)
    #     assert html =~ "Profile updated successfully"
    #   end

    #   test "deletes profile in listing", %{conn: conn, profile: profile} do
    #     {:ok, index_live, _html} = live(conn, ~p"/profile")

    #     assert index_live |> element("#profile-#{profile.id} a", "Delete") |> render_click()
    #     refute has_element?(index_live, "#profile-#{profile.id}")
    #   end
    # end

    # describe "Show" do
    #   setup [:create_profile]

    #   test "displays profile", %{conn: conn, profile: profile} do
    #     {:ok, _show_live, html} = live(conn, ~p"/profile/#{profile}")

    #     assert html =~ "Show Profile"
    #   end

    #   test "updates profile within modal", %{conn: conn, profile: profile} do
    #     {:ok, show_live, _html} = live(conn, ~p"/profile/#{profile}")

    #     assert show_live |> element("a", "Edit") |> render_click() =~
    #              "Edit Profile"

    #     assert_patch(show_live, ~p"/profile/#{profile}/show/edit")

    #     assert show_live
    #            |> form("#profile-form", profile: @invalid_attrs)
    #            |> render_change() =~ "can&#39;t be blank"

    #     assert show_live
    #            |> form("#profile-form", profile: @update_attrs)
    #            |> render_submit()

    #     assert_patch(show_live, ~p"/profile/#{profile}")

    #     html = render(show_live)
    #     assert html =~ "Profile updated successfully"
    #   end
  end
end
