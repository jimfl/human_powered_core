defmodule HumanPowered.Site do
  @moduledoc """
  Information about a site and how to build it.

  ### `site_name`

   The title of the site.

  ### `site_tagline`

  A subtitle that can be incorproated into page templates.

   ### `source_path`

  The top level of where the builder will look for the `.md` files which make up the site. 
  Other paths will be relative to this.

  ### `source_media_paths`

  Where the builder will look for referenced images. It will look in multiple
  places if necessary. Relative paths are relative to `source_path`

  ### `output_path`

  Where the builder will deposit HTML and copied images. 

  Relative paths will be relative to the current working directory. Using a
  fully-qualified path may result in fewer surprises.

  ### `source_media_paths`

  Where the builder will look for referenced images. It will look in multiple
  places if necessary.  	relative paths are relative to `source_path`.

  """

  defstruct site_name: "",
            site_tagline: "",
            source_path: "",
            output_path: "",
            source_media_paths: [],
            output_media_path: "",
            root_url: "",
            entry_cache: []

  alias HumanPowered.Entry
  alias HumanPowered.Site

  @default_config "sites.toml"
  @config_key_map %{
    site_name: "site_name",
    site_tagline: "site_tagline",
    source_path: "source_path",
    output_path: "output_path",
    source_media_paths: "source_media_paths",
    output_media_path: "output_media_path",
    root_url: "root_url",
  }

  @doc """
  Get the entries associated with the site. These may already cached in the site
  struct. To force a reload use `force_read: true`.

  Returns: list of %HumanPowered.Entry{}
  """
  def entries(site, options \\ [])

  def entries(%Site{source_path: path, entry_cache: []}, _) do
    Entry.read_from_directory(path)
  end

  def entries(%Site{} = site, force_read: true) do
    entries(%{site | entry_cache: []})
  end

  def entries(%Site{entry_cache: cached_entries}, _) do
    cached_entries
  end

  @doc """
  Load the entries for the site and cache them in the site struct.

  Returns: %HumanPowered.Site{}
  """
  def cache_entries(site) do
    %{site | entry_cache: entries(%{site | entry_cache: []})}
  end

  @doc """
  Get a list of fully-qualified filesystem paths of where to look for
  images in the site source.

  Returns: list of binary
  """
  def resolve_source_media_paths(site) do
    site.source_media_paths
    |> Enum.map(&resolve_path(&1, site.source_path))
  end

  @doc """
  Get the fully-qualified path for where to copy images into the site output.
  """
  def resolve_output_media_path(site) do
    resolve_path(site.output_media_path, site.output_path)
  end

  def resolve_path("/" <> _ = path, _), do: path

  def resolve_path("~" <> _ = path, _), do: Path.expand(path)

  def resolve_path(path, relative_to) do
    Path.join(relative_to, path) |> Path.expand()
  end

  @doc """
  Load one or more site configs from a TOML config file. The default is
  `sites.toml`.
  """
  def from_config(path \\ @default_config) do
    with {:ok, toml} <- File.read(path |> Path.expand()),
         {:ok, data} <- Toml.decode(toml) do
      {:ok, data |> parse_config()}
    else
      {:error, :enoent} ->
        {:error, "Config file #{path} not found."}

      {:error, :eacces} ->
        {:error, "Access denied to config file #{path}."}

      {:error, :enomem} ->
        {:error, "Config file #{path} too large."}

      {:error, {:invalid_toml, details}} ->
        {:error, "Config file #{path} has format error: #{details}"}
    end
  end

  def parse_config(%{"site" => sites}) do
    for {id, data} <- sites, into: %{} do
      {id, data |> parse_site()}
    end
  end

  def parse_config(_) do
    {:error, "config data did not have a 'site' element"}
  end

  def parse_site(site_data) do
    raw =
      for {key, config_key} <- @config_key_map, Map.has_key?(site_data, config_key), into: %{} do
        {key, Map.get(site_data, config_key)}
      end

    Map.merge(%Site{}, raw)
  end

  def validate_site_config(site) do
    with :ok <- validate_site_paths(site) do
      :ok
    end
  end

  def validate_site_paths(site) do
    with :ok <- path_exists?(site.source_path, "source_path"),
         :ok <- path_exists?(site.output_path, "output_path"),
         :ok <- path_exists?(Site.resolve_output_media_path(site), "output_media_path") do
      :ok
    end
  end

  def non_trivial?(value, config_field) when is_binary(value) do
    case String.length(value) do
      0 -> {:warning, "#{config_field} is not set."}
      _ -> :ok
    end
  end

  def path_exists?(path, config_field) do
    with true <- File.exists?(path) do
      :ok
    else
      {:error, _} -> {:error, "[#{config_field}] #{path} does not exist."}
    end
  end
end
