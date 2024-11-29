defmodule VimperfectWeb.Plugs.SetUser do
  import Plug.Conn

  alias Vimperfect.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)

    case user_id do
      nil -> assign(conn, :user, nil)
      user_id -> conn |> assign(:user, Accounts.get_user(user_id))
    end
  end
end
