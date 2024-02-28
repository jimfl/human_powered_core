defmodule Mix.Tasks.Hup.List do
  use Mix.Task
  alias HumanPowered.Util

  def run(args) do
    with {opts, _, _} <- OptionParser.parse(args, switches: [], strict: false),
         {:ok, config_data} <- Util.get_config_data(opts) do
      for {id, %{site_name: name}} <- config_data do
        IO.puts("#{id}:\t#{name}")
      end
    else
      {:error, reason} -> IO.puts(:stderr, "Error: " <> reason)
    end
  end
end
