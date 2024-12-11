defmodule VimperfectWeb.PuzzleHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use VimperfectWeb, :html

  embed_templates "puzzle_html/*"
end
