defmodule Vimperfect.Playground.Ssh.CliTest do
  @moduledoc """
  Tests how the `Vimperfect.Playground.Ssh.Cli` module works in isolation from the daemon.
  """
  use ExUnit.Case, async: true
  alias Vimperfect.Playground.Ssh.TermInfo.Xterm256color
  alias Vimperfect.Playground.Ssh.Cli

  describe "ctx/1" do
    test "returns the context" do
      ctx =
        Cli.ctx(%{
          cols: 10,
          rows: 20,
          conn: self(),
          chan: 0,
          term_mod: Xterm256color
        })

      assert ctx.size == {10, 20}
      assert ctx.chan == 0
      assert ctx.conn == self()
      assert ctx.term_mod == Xterm256color
    end
  end
end
