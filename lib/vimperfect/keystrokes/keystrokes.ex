# Heavily inspired by https://github.com/igrigorik/vimgolf/blob/master/lib/vimgolf/lib/vimgolf/keylog.rb
defmodule Vimperfect.Keystrokes do
  @kc_1byte Enum.map(0..255, &Vimperfect.Keystrokes.OneByteKeycodes.keycode_1byte/1)

  @kc_mbyte %{
    "k1" => "<F1>",
    "k2" => "<F2>",
    "k3" => "<F3>",
    "k4" => "<F4>",
    "k5" => "<F5>",
    "k6" => "<F6>",
    "k7" => "<F7>",
    "k8" => "<F8>",
    "k9" => "<F9>",
    "k;" => "<F10>",
    "F1" => "<F11>",
    "F2" => "<F12>",
    "F3" => "<F13>",
    "F4" => "<F14>",
    "F5" => "<F15>",
    "F6" => "<F16>",
    "F7" => "<F17>",
    "F8" => "<F18>",
    "F9" => "<F19>",
    "%1" => "<Help>",
    "&8" => "<Undo>",
    "#2" => "<S-Home>",
    "*7" => "<S-End>",
    "K1" => "<kHome>",
    "K4" => "<kEnd>",
    "K3" => "<kPageUp>",
    "K5" => "<kPageDown>",
    "K6" => "<kPlus>",
    "K7" => "<kMinus>",
    "K8" => "<kDivide>",
    "K9" => "<kMultiply>",
    "KA" => "<kEnter>",
    "KB" => "<kPoint>",
    "KC" => "<k0>",
    "KD" => "<k1>",
    "KE" => "<k2>",
    "KF" => "<k3>",
    "KG" => "<k4>",
    "KH" => "<k5>",
    "KI" => "<k6>",
    "KJ" => "<k7>",
    "KK" => "<k8>",
    "KL" => "<k9>",
    "kP" => "<PageUp>",
    "kN" => "<PageDown>",
    "kh" => "<Home>",
    "@7" => "<End>",
    "kI" => "<Insert>",
    "kD" => "<Del>",
    "kb" => "<BS>",
    "ku" => "<Up>",
    "kd" => "<Down>",
    "kl" => "<Left>",
    "kr" => "<Right>",
    "#4" => "<S-Left>",
    "%i" => "<S-Right>",
    "kB" => "<S-Tab>",
    <<0xFF, 0x58>> => "<C-Space>",
    <<0xFE, 0x58>> => "<0x80>",
    <<0xFC, 0x02>> => "<S->",
    <<0xFC, 0x04>> => "<C-Space>",
    <<0xFC, 0x06>> => "<C-S->",
    <<0xFC, 0x08>> => "<A->",
    <<0xFC, 0x0A>> => "<A-S->",
    <<0xFC, 0x0C>> => "<C-A>",
    <<0xFC, 0x0E>> => "<C-A-S->",
    <<0xFC, 0x10>> => "<M->",
    <<0xFC, 0x12>> => "<M-S->",
    <<0xFC, 0x14>> => "<M-C->",
    <<0xFC, 0x16>> => "<M-C-S->",
    <<0xFC, 0x18>> => "<M-A->",
    <<0xFC, 0x1A>> => "<M-A-S->",
    <<0xFC, 0x1C>> => "<M-C-A>",
    <<0xFC, 0x1E>> => "<M-C-A-S->",
    <<0xFD, 0x04>> => "<S-Up>",
    <<0xFD, 0x05>> => "<S-Down>",
    <<0xFD, 0x06>> => "<S-F1>",
    <<0xFD, 0x07>> => "<S-F2>",
    <<0xFD, 0x08>> => "<S-F3>",
    <<0xFD, 0x09>> => "<S-F4>",
    <<0xFD, 0x0A>> => "<S-F5>",
    <<0xFD, 0x0B>> => "<S-F6>",
    <<0xFD, 0x0C>> => "<S-F7>",
    <<0xFD, 0x0D>> => "<S-F9>",
    <<0xFD, 0x0E>> => "<S-F10>",
    <<0xFD, 0x0F>> => "<S-F10>",
    <<0xFD, 0x10>> => "<S-F11>",
    <<0xFD, 0x11>> => "<S-F12>",
    <<0xFD, 0x12>> => "<S-F13>",
    <<0xFD, 0x13>> => "<S-F14>",
    <<0xFD, 0x14>> => "<S-F15>",
    <<0xFD, 0x15>> => "<S-F16>",
    <<0xFD, 0x16>> => "<S-F17>",
    <<0xFD, 0x17>> => "<S-F18>",
    <<0xFD, 0x18>> => "<S-F19>",
    <<0xFD, 0x19>> => "<S-F20>",
    <<0xFD, 0x1A>> => "<S-F21>",
    <<0xFD, 0x1B>> => "<S-F22>",
    <<0xFD, 0x1C>> => "<S-F23>",
    <<0xFD, 0x1D>> => "<S-F24>",
    <<0xFD, 0x1E>> => "<S-F25>",
    <<0xFD, 0x1F>> => "<S-F26>",
    <<0xFD, 0x20>> => "<S-F27>",
    <<0xFD, 0x21>> => "<S-F28>",
    <<0xFD, 0x22>> => "<S-F29>",
    <<0xFD, 0x23>> => "<S-F30>",
    <<0xFD, 0x24>> => "<S-F31>",
    <<0xFD, 0x25>> => "<S-F32>",
    <<0xFD, 0x26>> => "<S-F33>",
    <<0xFD, 0x27>> => "<S-F34>",
    <<0xFD, 0x28>> => "<S-F35>",
    <<0xFD, 0x29>> => "<S-F36>",
    <<0xFD, 0x2A>> => "<S-F37>",
    # KE_IGNORE
    <<0xFD, 0x35>> => nil,
    <<0xFD, 0x4F>> => "<kInsert>",
    <<0xFD, 0x50>> => "<kDel>",
    # :help <CSI>
    <<0xFD, 0x51>> => "<0x9b>",
    # 7.2 compat
    <<0xFD, 0x53>> => "<C-Left>",
    # 7.2 compat
    <<0xFD, 0x54>> => "<C-Right>",
    # 7.2 <C-Home> conflict
    <<0xFD, 0x55>> => "<C-Left>",
    # 7.2 <C-End> conflict
    <<0xFD, 0x56>> => "<C-Right>",
    <<0xFD, 0x57>> => "<C-Home>",
    <<0xFD, 0x58>> => "<C-End>"
  }

  @doc """
  Strips exit sequnce `:wq<CR>` from the end of the solution.
  """
  def strip_exit_sequence({solution, score}) do
    {exit_sequence, exit_sequence_score} =
      Application.get_env(:vimperfect, Vimperfect.Playground)
      |> Keyword.get(:stripped_exit_sequence, {":wq<CR>", 4})

    {String.trim_trailing(solution, exit_sequence), score - exit_sequence_score}
  end

  @doc """
  Converts from keystrokes from the format that nvim produces with `-W` option to a more readable format.
  """
  @spec convert_keystrokes(input :: String.t()) :: {converted :: String.t(), score :: integer()}
  def convert_keystrokes(input) when is_binary(input) do
    do_convert(:binary.bin_to_list(input), "", 0)
  end

  defp do_convert([0x80, b2, b3 | rest], acc, score) do
    code = @kc_mbyte[<<b2, b3>>] || ""
    do_convert(rest, acc <> code, score + 1)
  end

  defp do_convert([b | rest], acc, score) do
    code = Enum.at(@kc_1byte, b, "")
    do_convert(rest, acc <> code, score + 1)
  end

  defp do_convert([], acc, score) do
    {acc, score}
  end
end
