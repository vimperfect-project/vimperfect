defmodule Vimperfect.Playground.Ssh.Connection do
  @moduledoc """
  A set of utilities for workking with ssh connection
  """
  alias Vimperfect.Playground.Ssh.Handler
  require Logger

  @doc """
  Prints the message to the conneciton console followed by a newline.
  """
  @spec puts(Handler.context(), msg :: iodata()) :: :ok
  @callback puts(Handler.context(), msg :: iodata()) :: :ok
  def puts(ctx, msg, opts \\ []) do
    if Keyword.get(opts, :multiline, false) do
      write(ctx, msg |> String.replace("\n", "\n\r"))
    else
      write(ctx, msg <> "\n\r")
    end
  end

  @doc """
  Writes the message to the connection.
  """
  @spec write(Handler.context(), msg :: iodata()) :: :ok
  @callback write(Handler.context(), msg :: iodata()) :: :ok
  def write(ctx, msg) do
    :ssh_connection.send(ctx.conn, ctx.chan, msg)
    :ok
  end

  @spec clear_screen(Handler.context()) :: :ok
  @callback clear_screen(Handler.context()) :: :ok
  def clear_screen(ctx) do
    clear_seq = ctx.term_mod.clear()
    write(ctx, clear_seq)
  end

  @doc """
  Used to reply to an SSH request
  """
  @spec reply_request(
          ctx :: Handler.context(),
          wr :: boolean(),
          status :: atom()
        ) ::
          :ok
  @callback reply_request(
              ctx :: Handler.context(),
              wr :: boolean(),
              status :: atom()
            ) :: :ok
  def reply_request(ctx, wr, status) do
    :ssh_connection.reply_request(ctx.conn, wr, status, ctx.chan)
  end

  def close(ctx) do
    :ssh_connection.close(ctx.conn, ctx.chan)
  end
end
