defmodule Vimperfect.Playground.Ssh.SshUtilsTest do
  @moduledoc """
  Tests how the `Vimperfect.Playground.Ssh.SshUtils` module works.
  """
  use ExUnit.Case, async: true
  alias Vimperfect.Playground.Ssh.Util

  test "addr_to_string/1 converts address to string" do
    assert Util.addr_to_string({{127, 0, 0, 1}, 80}) == "127.0.0.1:80"
  end
end
