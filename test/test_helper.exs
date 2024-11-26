Mox.defmock(EditorControlsMock, for: Vimperfect.Playground.Editor.Controls)
Mox.defmock(EditorRunnerMock, for: Vimperfect.Playground.Editor.RunnerBehaviour)
Mox.defmock(SshConnectionMock, for: Vimperfect.Playground.Ssh.Connection)
Mox.defmock(RunnerCallbacksMock, for: Tests.Support.RunnerCallbacks)
Mox.defmock(SshHandlerMock, for: Vimperfect.Playground.Ssh.Handler)

ExUnit.configure(exclude: [integration: true])

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Vimperfect.Repo, :manual)
