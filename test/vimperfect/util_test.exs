defmodule Vimperfect.UtilTest do
  use ExUnit.Case, async: true
  alias Vimperfect.Util

  describe "valid_openssh_public_key?/1" do
    test "returns true for a valid RSA public key" do
      assert Util.valid_openssh_public_key?(
               "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDZpN5HUZOjsu6hKpSyd3O7L4a4WI+SW+w5gpbLrK1uCGn5e4W1g+xBQSKFcuz3HAVb1Dn3unQMY8fQq4NUGN9OI+45jMti/Jm0Wdsib6OfKGAAxjrG3khQ8BpqIGb/eY9vgW40FbEr80PCCcgHDlUbvMeH52Qs0ub/ZgAlisddew=="
             )
    end

    test "returns true for a valid ECDSA public key" do
      assert Util.valid_openssh_public_key?(
               "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBDYL+KX2ZxPw3xLF0ylx5p5TkrS1DcTPiuLAtG0PyoXc6TCIawIfJJqHBIJXy1qfQ+kQ8w7Jo+iI4LXNoV+LnFE="
             )
    end

    test "returns true for a valid ED25519 public key" do
      assert Util.valid_openssh_public_key?(
               "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINyizBzsyvs5KYsyKdTgcpbw52tpEPmfl1q3m9VD5+V7"
             )
    end

    test "returns true for a valid DSA public key" do
      assert Util.valid_openssh_public_key?(
               "ssh-dss AAAAB3NzaC1kc3MAAACBAJHxyc389QD3Hp9OQPWQ6cfT0gRgQpnVSfcL+mwVCI2nnkvTUovKT6b/9S6Pbv7El0XAmxOV7HUHhFCV3zFfFEm5GS5levtFk56AqjEysa0yB2Cd+xlvstjLkr+lqpH6pwHJ6O+8EkMUxaZbj3IuOyuVPs8oGMTw3pcy087p8/mbAAAAFQDaU+4RCvoCW8bnciOBy7uCOJtrIwAAAIEAjYk/vW1I07YHdbvYrJaQifjsAxv8uFxE0o1H4ghTLf8B8Z16TS1XF7+tOKjqm17oGzivqb9A/Z69oYdY9CIajhwGUKDjk06OZPy1yzJ9yuhCdN97VRfCdD+GHezKNM6iefOwS8U9BF70LK1UoQFQcfNAZQ7/WN9B6s/5EmKvFE0AAACACRu+4+U1gJzTuO6bnnlyHBlWeQtlDafgiAjbyJiGGgSr+LgdUu3sxzGQTZD5kv87Wdh3hQaWYrfY/y5c4LVKsB2MsyuANsGUNaBwhsbSKLqjHFETxvqvWs3MSJoCb6eT/o5j/PiA7RfeO+wekxWvJ0+IhWhr8QX1jYH0kXK8P58e"
             )
    end

    test "returns true for ecdsa-sha2-nistp256 public key" do
      assert Util.valid_openssh_public_key?(
               "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBDYL+KX2ZxPw3xLF0ylx5p5TkrS1DcTPiuLAtG0PyoXc6TCIawIfJJqHBIJXy1qfQ+kQ8w7Jo+iI4LXNoV+LnFE="
             )
    end

    test "returns true for sk-ecdsa-sha2-nistp256@openssh.com public key" do
      assert Util.valid_openssh_public_key?(
               "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHzzFhEdSKzRC+nWuBU+aY/qcDWqVCwf0PV/c1J9f88Oem+eedTmDBid7Dp7hWDlVsLNsRjmh+NxIvln2nY2T/s="
             )
    end
  end

  describe "strip_openssh_public_key_comment/1" do
    test "strips the comment from the public key" do
      assert Util.strip_openssh_public_key_comment(
               "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHzzFhEdSKzRC+nWuBU+aY/qcDWqVCwf0PV/c1J9f88Oem+eedTmDBid7Dp7hWDlVsLNsRjmh+NxIvln2nY2T/s= kwinso@fedora"
             ) ==
               "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHzzFhEdSKzRC+nWuBU+aY/qcDWqVCwf0PV/c1J9f88Oem+eedTmDBid7Dp7hWDlVsLNsRjmh+NxIvln2nY2T/s="
    end
  end
end
