defmodule HumanPowered.Entry do
  defstruct title: "",
            subtitle: "",
            date: Date.utc_today(),
            tags: [],
            summary: "",
            image: "",
            path: "",
            text: "",
            prev: "",
            next: ""

  alias HumanPowered.Entry

  @doc """
  Reads all markdown files in a directory as entries.

  Returns: A list of entries
  """

  def read_from_directory(path) do
    for filename <- Path.expand(path) |> Path.join("*.md") |> Path.wildcard() do
      read_from_file(filename)
    end
    |> Enum.sort({:desc, Entry})
    |> sequence()
  end

  @doc """
  Reads an entry from a Markdown file with a YAML metadata preamble.

  Returns: %HumanPowered.Entry{}
  """

  def read_from_file(filename) do
    title = Path.basename(filename) |> Path.rootname()

    with [_, meta, md] <-
           filename
           |> Path.expand()
           |> File.read!()
           |> String.split("---") do
      %Entry{title: title, text: md}
      |> Map.merge(extract_attributes(meta))
      |> retype_date()
      |> extract_summary()
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def extract_attributes(meta, struct_name \\ Entry) do
    valid_keys =
      struct(struct_name, %{})
      |> Map.keys()
      |> Enum.map(&Atom.to_string/1)
      |> Enum.filter(&(not String.starts_with?(&1, "_")))

    atomic_yaml(meta, valid_keys)
  end

  # convert from a map that has strings as keys to a map that has atoms
  # as keys, but only if they appear in a list of specific keys.
  def atomic_yaml(yaml, valid_keys) do
    with {:ok, attrs} <- YamlElixir.read_from_string(yaml) do
      for {k, v} <- attrs, Enum.member?(valid_keys, String.downcase(k)), into: %{} do
        {String.to_atom(k), v}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def retype_date(%Entry{date: value} = entry) when is_binary(value) do
    %{entry | date: Date.from_iso8601!(value)}
  end

  def retype_date(entry), do: entry

  # If the summary is empty, use the first paragraph
  def extract_summary(%Entry{summary: ""} = entry) do
    summary =
      entry.text
      |> String.split("\n\n", trim: true)
      |> List.first()

    %{entry | summary: summary}
  end

  # If the site already has a summary, leave it alone.
  def extract_summary(entry), do: entry

  # Used for sorting
  def compare(entry1, entry2), do: Date.compare(entry1.date, entry2.date)

  @doc """
  Adds `prev` and `next` links to an ordered list of entries.
  """

  def sequence(entries), do: sequence([], entries)

  def sequence([prev | _] = predecessors, [current | []]) do
    [%{current | prev: prev.path} | predecessors] |> Enum.reverse()
  end

  def sequence([], [first | [second | _] = rest]) do
    sequence([%{first | next: second.path}], rest)
  end

  def sequence([prev | _] = predecessors, [current | [next | _] = successors]) do
    sequence([%{current | prev: prev.path, next: next.path} | predecessors], successors)
  end

  def extract_images(entry) do
    images =
      Regex.scan(~r/\!\[\[([^\]]+)\]\]/, entry.text)
      |> Enum.map(&List.last/1)

    [entry.image | images]
  end

  def get_tags(entries), do: get_tags(entries, [])

  def get_tags([], acc), do: Enum.uniq(acc)

  def get_tags([%Entry{tags: tags} | rest], acc) do
    get_tags(rest, tags ++ acc)
  end

  def get_tagged_entries(entries, tag) do
    entries
    |> Enum.filter(&Enum.member?(&1.tags, tag))
  end
end
