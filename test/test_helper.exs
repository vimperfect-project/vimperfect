ExUnit.configure(exclude: [integration: true])

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Vimperfect.Repo, :manual)
