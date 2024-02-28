defmodule HumanPowered.Text do
  def extract_wiki_links(text), do: wiki_links(text, [])

  defp wiki_links("", links), do: links

  defp wiki_links(<<"![[", rest::binary>>, links) do
    {link, rest} = wiki_extract(rest, "")
    wiki_links(rest, [link | links])
  end

  defp wiki_links(<<_::utf8, rest::binary>>, links), do: wiki_links(rest, links)

  defp wiki_extract("", acc), do: {acc, ""}
  defp wiki_extract(<<"]]", rest::binary>>, acc), do: {acc, rest}

  defp wiki_extract(<<char::utf8, rest::binary>>, acc) do
    wiki_extract(rest, <<acc::binary, char>>)
  end
end
