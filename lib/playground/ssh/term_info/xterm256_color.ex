defmodule Vimperfect.Playground.Ssh.TermInfo.Xterm256color do
  @moduledoc """
  This one is also "based on" ausimian/garnish. IDK what is hapenning here thb
  """

  use Vimperfect.Playground.Ssh.TermInfo

  def smcup(), do: "\e[?1049h"
  def rmcup(), do: "\e[?1049l"
  def smkx(), do: "\e[?1h\e="
  def rmkx(), do: "\e[?1l\e>"
  def clear(), do: "\e[H\e[2J"
  def civis(), do: "\e[?25l"
  def cnorm(), do: "\e[?12l\e[?25h"

  def colors(), do: 256

  def cup(row, col) do
    <<"\e[", Integer.to_string(row + 1)::binary, ?;, Integer.to_string(col + 1)::binary, ?H>>
  end

  def setaf(fg) when is_integer(fg) do
    <<
      "\e[",
      cond do
        fg < 8 -> <<?3, Integer.to_string(fg)::binary>>
        fg < 16 -> <<?9, Integer.to_string(fg - 8)::binary>>
        true -> <<"38;5;", Integer.to_string(fg)::binary>>
      end::binary,
      ?m
    >>
  end

  def setab(bg) when is_integer(bg) do
    <<
      "\e[",
      cond do
        bg < 8 -> <<?4, Integer.to_string(bg)::binary>>
        bg < 16 -> <<"10"::binary, Integer.to_string(bg - 8)::binary>>
        true -> <<"48;5;", Integer.to_string(bg)::binary>>
      end::binary,
      ?m
    >>
  end

  def sgr(flags) when is_integer(flags) do
    <<
      if(bitset?(flags, 8), do: "\e(0", else: "\e(B")::binary,
      "\e[0"::binary,
      if(bitset?(flags, 5), do: ";1", else: "")::binary,
      if(bitset?(flags, 4), do: ";2", else: "")::binary,
      if(bitset?(flags, 1), do: ";4", else: "")::binary,
      if(bitset?(flags, 0) || bitset?(flags, 2), do: ";7", else: "")::binary,
      if(bitset?(flags, 3), do: ";5", else: "")::binary,
      if(bitset?(flags, 6), do: ";8", else: "")::binary,
      ?m
    >>
  end

  def sgr0(), do: "\e(B\e[m"
end
