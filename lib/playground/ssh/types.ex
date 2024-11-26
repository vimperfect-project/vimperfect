defmodule Vimperfect.Playground.Ssh.Types do
  @moduledoc """
  This module contains types used by the ssh server and client.
  """
  @type peer_address :: {ip_address, port_number}
  @type ip_address :: :inet.ip_address()
  @type port_number :: :inet.port_number()

  @type public_key_status :: :no_public_key | :with_public_key
end
