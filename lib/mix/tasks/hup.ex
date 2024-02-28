defmodule Mix.Tasks.Hup do
  use Mix.Task

  @moduledoc """
  The `hup` task supports two commands:
  `mix hup.build` for rebuilding sites, and
  `mix hup.list` for listing the sites in a config

  use `mix help` to get details for both comands.
  """

  @impl Mix.Task
  def run(_) do
    IO.puts("""
    Tasks: 
    mix hup.list [--config path] - list sites in config file  
    mix hup.build [--config path] [site] - build site(s)
    """)
  end
end
