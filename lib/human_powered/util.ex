defmodule HumanPowered.Util do
  alias HumanPowered.Site

  # Used by mix tasks
  def get_config_data(opts) do
    cond do
      Keyword.has_key?(opts, :config) ->
        Keyword.get(opts, :config)
        |> Path.expand()
        |> Site.from_config()

      true ->
        Site.from_config()
    end
  end
end
