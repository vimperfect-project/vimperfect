defmodule Vimperfect.Repo do
  use Ecto.Repo,
    otp_app: :vimperfect,
    adapter: Ecto.Adapters.Postgres
end
