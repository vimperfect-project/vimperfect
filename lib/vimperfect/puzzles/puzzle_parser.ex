defmodule Vimperfect.Puzzles.MarkdownParser do
  @moduledoc """
  This module allows parsing markdown puzzle descriptions into a puzzle struct.
  """
  alias Vimperfect.Puzzles.Puzzle

  @doc """
  Expects a filename and markdown file contents and converts it to a puzzle struct according to the markdown template.
  The filename is used to generate the puzzle slug, which is used as the URL slug.

  ## How file contents are parsed into a puzzle
  The first thing that is parsed is the frontmatter. The frontmatter is a yaml block at the top of the file
  that contains information about the puzzle, such as:
  - **author**. The username of the author of the puzzle, the author will be fetched from the database
  - **complexity**. The complexity of the puzzle, can be either "easy", "medium" or "hard"
  - **filename**. The filename of the puzzle, is used inside of the editor to show the filename. Defaults to "input.txt"

  Example of frontmatter:
  ```yaml
  author: bob
  complexity: easy
  filename: main.py
  ```

  The next node is the title, which is required to be an H1 heading. The title is used to generate the puzzle name.

  After that, the description is parsed. It is a sequence of markdown nodes which are parsed until a "Hints" heading is found.
  All of these nodes are concatenated together and used as the description of the puzzle and kept in the markdown format.

  Next, the hints are parsed. Hints are extracted from the first list node after the "Hints" heading. Each hint is a list item
  and is converted to a markdown string. Hints are kept in the same order as they appear in the markdown file.

  Finally, the initial content and expected content are parsed. The initial content is extracted from the first code block
  after the "Initial content" heading, deriving the language from the code block info.

  Similarly, the expected content is extracted from the first code block after the "Expected content" heading, deriving the language from the code block info.

  At the end, the author is fetched from the database and the puzzle struct is returned. No records are created in the database.
  """
  @spec from_markdown(filename :: binary(), content :: binary()) :: Puzzle
  def from_markdown(filename, content) do
    %MDEx.Document{nodes: nodes} =
      MDEx.parse_document!(content, extension: [front_matter_delimiter: "---"])

    {author_username, complexity, puzzle_filename} = parse_frontmatter(nodes)
    title = parse_title(nodes)

    description = parse_description(nodes)

    hints_list = parse_hints(nodes)

    {init_lang, init_code} = parse_code_block_content(nodes, "initial content")
    {expected_lang, expected_code} = parse_code_block_content(nodes, "expected content")

    user = Vimperfect.Accounts.get_user_by_username!(author_username)

    %Puzzle{
      name: title,
      slug: filename |> Path.basename() |> Path.rootname(),
      filename: puzzle_filename || "input.txt",
      complexity: complexity,
      author: user,
      description: description,
      hints: hints_list,
      initial_content: init_code |> String.trim(),
      initial_language: init_lang,
      expected_content: expected_code |> String.trim(),
      expected_language: expected_lang
    }
  end

  defp parse_title(nodes) do
    %MDEx.Heading{level: 1, nodes: [%MDEx.Text{literal: title}]} = Enum.at(nodes, 1)
    title
  end

  defp parse_description(nodes) do
    hints_heading_index = find_heading_index(nodes, "hints")

    nodes
    # First 2 nodes are front matter and title
    |> Enum.slice(2..(hints_heading_index - 1))
    |> to_commonmark()
  end

  defp parse_hints(nodes) do
    heading_index = find_heading_index(nodes, "hints")
    nodes = tail_from(nodes, heading_index + 1)
    %MDEx.List{nodes: hints} = get_first_of_type(nodes, MDEx.List)

    Enum.map(
      hints,
      fn %MDEx.ListItem{
           nodes: nodes
         } ->
        hint_markdown = %MDEx.Document{nodes: nodes} |> MDEx.to_commonmark!()
        hint_markdown |> String.trim()
      end
    )
  end

  defp parse_code_block_content(nodes, title) do
    title_index = find_heading_index(nodes, title)
    nodes = tail_from(nodes, title_index + 1)

    %MDEx.CodeBlock{fenced: true, info: lang, literal: code} =
      get_first_of_type(nodes, MDEx.CodeBlock)

    {lang, code}
  end

  defp tail_from(nodes, index) do
    Enum.slice(nodes, index..-1//1)
  end

  defp get_first_of_type(nodes, type) do
    Enum.find(nodes, &is_struct(&1, type))
  end

  defp find_heading_index(nodes, heading_text) do
    Enum.find_index(nodes, fn node ->
      case node do
        %MDEx.Heading{nodes: [%MDEx.Text{literal: cur_heading_text}]} ->
          String.downcase(cur_heading_text) == String.downcase(heading_text)

        _ ->
          false
      end
    end)
  end

  defp parse_frontmatter(nodes) do
    %MDEx.FrontMatter{literal: yaml} = get_first_of_type(nodes, MDEx.FrontMatter)

    frontmatter_fields =
      yaml
      |> String.replace("---", "")
      |> String.trim()
      |> YamlElixir.read_from_string!()

    %{"author" => author, "complexity" => complexity} = frontmatter_fields

    {author, parse_complexity(complexity), frontmatter_fields["filename"]}
  end

  defp parse_complexity("easy"), do: :easy
  defp parse_complexity("medium"), do: :medium
  defp parse_complexity("hard"), do: :hard

  defp to_commonmark(nodes) do
    %MDEx.Document{nodes: nodes} |> MDEx.to_commonmark!()
  end
end
