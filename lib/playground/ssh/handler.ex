defmodule Vimperfect.Playground.Ssh.Handler do
  @moduledoc """
  A behaviour for defining the handler for a SSH connection.

  This behaviour is intendeted to be used with the `Vimperfect.Playground.Ssh.Server` module.
  All server interaction is abstracted away from the handler, and it does not
  aim to be a full SSH CLI handler implementation, rather it is intended to
  solve the goals of the playground (authorizing connection and being able to spawn
  editor instances and give ability to control them to the connections)

  ## Order of callbacks
  - `auth`
  - `on_connect`
  - `init`
  - `on_ready`
  - `on_data` (multiple times)
  - `on_window_resize` (multiple times)
  - `on_disconnect`
  """

  alias Vimperfect.Playground.Ssh.Types
  @type row_count :: non_neg_integer()
  @type col_count :: non_neg_integer()
  @type dimension :: {col_count(), row_count()}
  @type context :: %{
          required(:size) => dimension(),
          required(:conn) => :ssh.connection_ref(),
          required(:term) => module(),
          required(:chan) => integer()
        }

  @doc """
  Called when a new SSH connection is established to the server.
  This will be after before the `Vimperfect.Playground.Ssh.Handler.auth/3` callback.

  At this step, there's no actual context that is passed, since the connection just appeared and no CLI was created at this point.
  """
  @callback on_connect(
              conn :: :ssh.connection_ref(),
              username :: String.t(),
              peer_address :: Types.peer_address(),
              method :: String.t()
            ) :: :ok

  @doc """
  Called when the client authenticates with the server, it is the first callback that is called when a new connection is established.

  It should return `:ok` if the authentication was successful, or `{:error, reason}` if it was not.
  """
  @callback auth(
              conn :: :ssh.connection_ref(),
              public_key :: :public_key.public_key(),
              user :: String.t()
            ) ::
              :ok | {:error, reason :: atom()}

  @doc """
  Init is called when ssh server passes the control to the CLI handler.
  At this point, client has not been setup (e.g. no terminal size, no pty, no env, etc.).

  """
  @callback init(context()) ::
              :ok | {:error, reason :: any()}

  @doc """
  When `Vimperfect.Playground.Ssh.Handler.ready/1` is called, the handler is guaranteed that the client is ready to accept data.
  You can safely assume that the client is ready to accept data from the server.
  """
  @callback on_ready(context()) ::
              :ok | {:error, reason :: any()}

  @doc """
  Called when data is received from the client.

  The handler is responsible for handling the data
  Data arrives on each keypress as binary.
  """
  @callback on_data(context(), data :: binary()) ::
              :ok | {:error, reason :: any()}

  @doc """
  Called when the client resizes the window.
  """
  @callback on_window_resize(context(), cols :: col_count(), rows :: row_count()) ::
              :ok | {:error, reason :: any()}

  @doc """
  Called when the client disconnects from the server.

  This is the right palce to clean up any resources that were allocated during the connection.
  """
  @callback on_disconnect(conn :: :ssh.connection_ref(), reason :: term()) :: :ok

  @callback on_terminate(context()) :: :ok
end
