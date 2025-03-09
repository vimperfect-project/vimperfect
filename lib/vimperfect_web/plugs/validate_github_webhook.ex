defmodule VimperfectWeb.Plugs.ValidateGithubWebhook do
  def init(opts), do: opts

  def call(conn, _opts) do
    _secret =
      Application.fetch_env!(:vimperfect, Vimperfect.GithubPuzzles)
      |> Keyword.fetch!(:webhook_secret)

    # TODO: validate that payload matches the signature

    conn
  end
end
