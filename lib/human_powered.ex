defmodule HumanPowered do
  @moduledoc """
  Documentation for `HumanPowered`.
  """

  alias HumanPowered.Template
  alias HumanPowered.Site
  alias HumanPowered.Entry

  @extension ".html"

  def generate_post_pages(site) do
    [first | rest] = Site.entries(site)
    generate_post_pages([], first, rest, site)
  end

  def generate_post_pages(later, current, [], site) do
    generate_single_post_page(current, later |> Enum.reverse(), site)
  end

  def generate_post_pages(later, current, earlier, site) do
    generate_single_post_page(
      current,
      (later |> Enum.reverse()) ++ earlier,
      site
    )

    [next | earlier] = earlier
    generate_post_pages([current | later], next, earlier, site)
  end

  def generate_single_post_page(main_entry, rest_entries, site) do
    html = Template.post_page(main_entry, rest_entries)

    Path.join(site.output_path, main_entry.path <> @extension)
    |> Path.expand()
    |> File.write!(html)
  end

  def generate_tag_page(entries, tag, site) do
    tagged_entries = Entry.get_tagged_entries(entries, tag)
    html = Template.summary_page(tagged_entries, "Posts tagged: #{tag}")

    Path.join(site.output_path, "tags/#{tag}" <> @extension)
    |> Path.expand()
    |> File.write!(html)
  end

  def generate_tag_pages(site) do
    entries = Site.entries(site)

    for tag <- Entry.get_tags(entries) do
      generate_tag_page(entries, tag, site)
    end
  end

  def generate_feed(site) do
    rss = Template.feed(site, site |> Site.entries())

    Path.join(site.output_path, "feed.xml")
    |> Path.expand()
    |> File.write!(rss)
  end

  def copy_latest_entry_to_index(site) do
    # Get the path of the most recent entry
    [%Entry{path: path} | _] = site |> Site.entries()

    File.copy(
      Path.join(site.output_path, path <> ".html"),
      Path.join(site.output_path, "index.html")
    )
  end
end
