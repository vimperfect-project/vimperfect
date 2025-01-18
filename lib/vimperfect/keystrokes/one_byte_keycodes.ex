# Elixir compiler behaves strangely with using in-module functions for
# module attributes, so this is why this generator function is defined here.
defmodule Vimperfect.Keystrokes.OneByteKeycodes do
  import Bitwise

  def keycode_1byte(n) do
    cond do
      n == 0x1B ->
        "<Esc>"

      n == 0x0D ->
        "<CR>"

      n == 0x0A ->
        "<NL>"

      n == 0x09 ->
        "<Tab>"

      n in 32..126 ->
        <<n>>

      n in 1..127 ->
        "<C-#{<<bxor(n, 0x40)>>}>"

      true ->
        val = Integer.to_string(n, 16) |> String.pad_leading(4, "0")
        "<#{val}>"
    end
  end
end
