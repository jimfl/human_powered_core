defmodule HumanPowered.Template do
  require EEx

  alias HumanPowered.Entry

  def format_date(date) do
    month = Calendar.strftime(date, "%B")
    "#{month} #{date.day}, #{date.year}"
  end

  def rfc822_date_time(date) do
    Calendar.strftime(date, "%a, %d %b %Y 00:00:00 GMT")
  end

  def to_html(entry) do
    entry = entry |> fix_image_refs("images")
    MDEx.to_html(entry.text)
  end

  def to_summary_html(entry) do
    MDEx.to_html(entry.summary)
  end

  # Obsidian images refs are wiki-style ![[filename.ext]]
  # Change them to markdown style, and insert a path to the media dir
  # ![](media/filename.ext)
  def fix_image_refs(entry, media_path) do
    new_text =
      entry.text
      |> String.replace(~r/\!\[\[([^\]]+)\]\]/, "![](#{media_path}/\\1)", global: true)

    %{entry | text: new_text}
  end

  def prev_button(%Entry{prev: ""}) do
    ~s(<li><a href="" class="disabled button large previous">Previous Post</a></li>)
  end

  def prev_button(%Entry{prev: prev}) do
    ~s(<li><a href="#{prev}.html" class="button large previous">Previous Post</a></li>)
  end

  def next_button(%Entry{next: ""}) do
    ~s(<li><a href="" class="disabled button large next">Next Post</a></li>)
  end

  def next_button(%Entry{next: next}) do
    ~s(<li><a href="#{next}.html" class="button large next">Next Post</a></li>)
  end

  EEx.function_from_file(:def, :mini_post, "templates/mini_post.eex", [:entry])

  EEx.function_from_file(:def, :post, "templates/post.eex", [:entry])

  EEx.function_from_file(:def, :post_page, "templates/blog_entry.eex", [:main_entry, :entries])

  EEx.function_from_file(:def, :summary, "templates/post_summary.eex", [:entry])

  EEx.function_from_file(:def, :summary_page, "templates/summary_page.eex", [:entries, :title])

  EEx.function_from_file(:def, :feed, "templates/rss.eex", [:site, :entries])
end
