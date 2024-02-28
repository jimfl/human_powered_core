defmodule Mix.Tasks.Hup.Init do
  @moduledoc """
  Initialize one or more HumanPowered sites listed in the config file, creating
  the directory structure and copying the style assets to the output directory.
  The default is to  initialize all  of the sites in the config file. the
  `--config` option specifies the file to use as config. The default is to use
  `sites.toml` in the current working directory.

    mix hup.build [--config sites.toml] [site [site ...]]
  """

  use Mix.Task

  alias HumanPowered.Util

  def run(args) do
    with {opts, sites, _} <- OptionParser.parse(args, switches: [], strict: false),
         {:ok, config_data} <- Util.get_config_data(opts) do
      init_sites(sites, config_data)
    else
      {:error, reason} -> IO.puts(:stderr, "Error: " <> reason)
    end
  end

  # passing in an empty list of sites means build all the sites 
  # listed in the configuration
  def init_sites([], config) do
    init_sites(Map.keys(config), config)
  end

  # This is the recursion exit condition, rather than the empty
  # list, which has different semantics (see above)
  def init_sites([id | []], config) do
    init_site(id, config)
  end

  def init_sites([id | rest], config) do
    init_site(id, config)
    init_sites(rest, config)
  end

  def init_site(id, config) do
    with %{^id => site} <- config,
      script <- EEx.eval_file("templates/init_script.eex", site: site),
      {:ok, file} <- write_temp(script),
      {_, _} <- System.cmd("sh", [file])
    do
      IO.puts("Initialized site '#{id}' in #{site.output_path}")
    else
      _ -> IO.puts(:stderr, "Site #{id} not found in config data.")
    end
  end

  def write_temp(contents) when is_binary(contents) do
    {file, _} = System.cmd("mktemp", [])
    file = String.trim(file)
    with :ok <- File.write(file, contents) do
      {:ok, file}
    else
      _ -> {:error, "could not write temporary file"}
    end
  end

end
