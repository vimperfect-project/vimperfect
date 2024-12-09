defmodule Vimperfect.Playground.Ssh.Authenticator do
  @moduledoc """
  This module satisfies the :ssh_server_key_api behaviour from the erlang :ssh module.
  For the most part, it just does nothing special, but for is_auth_key(), it will call
  the auth callback from the Vimperfect.Playground.Ssh.Handler behaviour based on the
  :ssh_cli paramater named :handler (this is expected to be set at the ssh daemon startup by the Vimperfect.Playground.Ssh.Server module)
  """

  @behaviour :ssh_server_key_api

  require Record

  Record.defrecord(
    :RSAPublicKey,
    Record.extract(:RSAPublicKey, from_lib: "public_key/include/public_key.hrl")
  )

  Record.defrecord(
    :RSAPrivateKey,
    Record.extract(:RSAPrivateKey, from_lib: "public_key/include/public_key.hrl")
  )

  Record.defrecord(
    :DSAPrivateKey,
    Record.extract(:DSAPrivateKey, from_lib: "public_key/include/public_key.hrl")
  )

  Record.defrecord(
    :"Dss-Parms",
    Record.extract(:"Dss-Parms", from_lib: "public_key/include/public_key.hrl")
  )

  @type public_key :: :public_key.public_key()
  @type private_key :: :public_key.private_key()
  @type public_key_algorithm :: :"ssh-rsa" | :"ssh-dss" | atom
  @type user :: charlist()
  @type daemon_options :: Keyword.t()

  require Logger

  @spec host_key(public_key_algorithm, daemon_options) ::
          {:ok, private_key} | {:error, any}
  def host_key(algorithm, daemon_options) do
    :ssh_file.host_key(algorithm, daemon_options)
  end

  @spec is_auth_key(term, user, daemon_options) :: boolean
  def is_auth_key(key, user, daemon_options) do
    {_, ssh_cli_opts} = daemon_options |> Keyword.get(:ssh_cli)
    handler = Keyword.get(ssh_cli_opts, :handler)

    case handler.auth(self(), key, user) do
      :ok ->
        true

      {:error, _reaso} ->
        false
    end
  end

  # server uses this to find individual keys for an individual user when
  # they try to log in with a public key
  @spec ssh_dir(:user | :system | {:remoteuser, user}, Keyword.t()) :: String.t()
  def ssh_dir({:remoteuser, _user}, _opts) do
    default_user_dir()
  end

  # server uses this to find server host keys
  def ssh_dir(:system, opts),
    do: Keyword.get(opts, :system_dir, "/etc/ssh")

  @perm700 0700

  @spec default_user_dir() :: binary
  def default_user_dir do
    {:ok, [[home | _]]} = :init.get_argument(:home)
    user_dir = Path.join(home, ".ssh")
    :ok = :filelib.ensure_dir(Path.join(user_dir, "dummy"))
    :ok = :file.change_mode(user_dir, @perm700)
    user_dir
  end
end
