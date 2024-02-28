defmodule Mix.Tasks.Hup.Build do
  @moduledoc """
   Build one or more HumanPowered sites listed in the config file. The default is to build all 
  of the sites in the config file. the `--config` option specifies the file to use as config.
   The default is to use `sites.toml` in the current working directory.

  `mix hup.build [--config sites.toml] [site [site ...]]`
  """

  use Mix.Task

  alias HumanPowered.Util
  alias HumanPowered.File

  def run(args) do
    with {opts, sites, _} <- OptionParser.parse(args, switches: [], strict: false),
         {:ok, config_data} <- Util.get_config_data(opts) do
      build_sites(sites, config_data)
    else
      {:error, reason} -> IO.puts(:stderr, "Error: " <> reason)
    end
  end

  # passing in an empty list of sites means build all the sites 
  # listed in the configuration
  def build_sites([], config) do
    build_sites(Map.keys(config), config)
  end

  # This is the recursion exit condition, rather than the empty
  # list, which has different semantics (see above)
  def build_sites([id | []], config) do
    build_site(id, config)
  end

  def build_sites([id | rest], config) do
    build_site(id, config)
    build_sites(rest, config)
  end

  def build_site(id, config) do
    with %{^id => site} <- config do
      IO.puts("Building site #{id}:\t#{site.site_name}...")
      start = Time.utc_now()
      HumanPowered.generate_post_pages(site)
      HumanPowered.generate_tag_pages(site)
      File.copy_images(site)
      HumanPowered.generate_feed(site)
      HumanPowered.copy_latest_entry_to_index(site)
      elapse = Time.diff(Time.utc_now(), start)
      IO.puts("Done. (#{elapse}s)")
    else
      _ -> IO.puts(:stderr, "Site #{id} not found in config data.")
    end
  end
end
