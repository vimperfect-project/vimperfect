defmodule Vimperfect.Util do
  @dss_regex ~r/^ssh-dss AAAAB3NzaC1kc3[0-9A-Za-z+\/]+[=]{0,3}$/
  @ecdsa_regex ~r/^ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNT[0-9A-Za-z+\/]+[=]{0,3}$/
  @nistp256_regex ~r/^sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb2[0-9A-Za-z+\/]+[=]{0,3}$/
  @ed25519_regex ~r/^ssh-ed25519 AAAAC3NzaC1lZDI1NTE5[0-9A-Za-z+\/]+[=]{0,3}$/
  @sk_regex ~r/^sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29t[0-9A-Za-z+\/]+[=]{0,3}$/
  @rsa_regex ~r/^ssh-rsa AAAAB3NzaC1yc2[0-9A-Za-z+\/]+[=]{0,3}$/

  @filename_regex ~r/^[\w\-\.]+$/

  @doc """
  Validates if the given public key is a valid OpenSSH public key. Important thing to note is that keys must not have a comment at the end.
  To strip the comment, use `Vimperfect.Util.strip_openssh_public_key_comment/1`
  """
  def valid_openssh_public_key?(public_key) do
    String.match?(public_key, @dss_regex) ||
      String.match?(public_key, @ecdsa_regex) ||
      String.match?(public_key, @nistp256_regex) ||
      String.match?(public_key, @ed25519_regex) ||
      String.match?(public_key, @sk_regex) ||
      String.match?(public_key, @rsa_regex)
  end

  @doc """
  Strips optional comment from the given public key.
  """
  def strip_openssh_public_key_comment(public_key) do
    public_key |> String.split(" ", trim: true) |> Enum.take(2) |> Enum.join(" ")
  end

  @doc """
  Returns true if the given filename is valid. Any filename that does only contain alphanumeric characters, underscores, dashes and dots is considered valid.
  """
  @spec valid_filename?(String.t()) :: boolean()
  def valid_filename?(filename) do
    String.match?(filename, @filename_regex)
  end
end
