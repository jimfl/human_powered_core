defmodule HumanPowered.File do
  alias HumanPowered.Site
  alias HumanPowered.Entry

  def copy_images(site) do
    Site.entries(site)
    |> Enum.flat_map(&Entry.extract_images/1)
    |> Enum.uniq()
    |> Enum.map(&copy_image(site, &1))
  end

  def copy_image(site, image) do
    source =
      Site.resolve_source_media_paths(site)
      |> Enum.map(&(Path.join(&1, image) |> Path.expand()))
      |> Enum.map(&file_and_timestamp/1)
      |> Enum.filter(&(&1 != nil))
      |> List.first()

    output_path =
      Site.resolve_output_media_path(site)
      |> Path.join(image)
      |> Path.expand()

    existing_output = file_and_timestamp(output_path)

    _copy_image(source, existing_output, output_path)
  end

  defp _copy_image(nil, _, output_path), do: {:error, "source not found. Output: #{output_path}"}

  defp _copy_image({source, _}, nil, output_path) do
    with {:ok, _} <- File.copy(source, output_path) do
      :ok
    else
      {:error, reason} -> {:error, reason, source, output_path}
    end
  end

  defp _copy_image({source, src_ts}, {output, out_ts}, _) when src_ts > out_ts do
    _copy_image({source, src_ts}, nil, output)
  end

  defp _copy_image(_, _, _) do
    :noop
  end

  def file_and_timestamp(path) do
    with {:ok, %File.Stat{mtime: mtime}} <- File.stat(path) do
      {path, :calendar.datetime_to_gregorian_seconds(mtime)}
    else
      {:error, _} -> nil
    end
  end
end
