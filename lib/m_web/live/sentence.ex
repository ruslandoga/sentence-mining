defmodule MWeb.SentenceLive do
  use MWeb, :live_view
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, temporary_assigns: [segments: [], sentence: nil]}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen lg:flex lg:items-center lg:justify-center">
      <div class="text-2xl p-6 flex max-w-screen-xl mx-auto">
        <.segment :for={{segment, idx} <- Enum.with_index(@segments)} id={idx} segment={segment} />
      </div>
    </div>
    """
  end

  defp segment(%{segment: segment} = assigns) do
    %{
      "part_of_speech" => part_of_speech,
      "lexical_form" => lexical_form,
      "surface_form" => surface_form,
      "entry" => entry
    } = segment

    assigns =
      assign(assigns,
        surface_form: surface_form,
        segment_class: segment_class(segment),
        lexical_form: lexical_form,
        part_of_speech: part_of_speech_eng(part_of_speech),
        entry: entry
      )

    ~H"""
    <span
      id={"segment-#{@id}"}
      class={["px-0.5", @segment_class]}
      data-template={"tippy-#{@id}"}
      phx-hook="TippyHook"
    >
      <%= @surface_form %>
    </span>
    <template :if={@part_of_speech && @entry} id={"tippy-#{@id}"}>
      <.tippy_content part_of_speech={@part_of_speech} lexical_form={@lexical_form} entry={@entry} />
    </template>
    """
  end

  defp tippy_content(%{entry: entry, part_of_speech: part_of_speech} = assigns) do
    entry = filter_entry(entry, part_of_speech)
    assigns = assign(assigns, entry: entry, reading: extract_reading(entry))

    ~H"""
    <div class="max-h-[35vh] overflow-auto">
      <div class="font-semibold p-1"><%= @part_of_speech %></div>
      <div class="p-1">
        <%= if @reading == @lexical_form or is_nil(@reading) do %>
          <%= @lexical_form %>
        <% else %>
          <%= @lexical_form %> 【<%= @reading %>】
        <% end %>
      </div>
      <div class="p-1 pt-0">
        <.entry_content :for={subentry <- @entry} entry={subentry} />
      </div>
    </div>
    """
  end

  defp filter_entry(entries, part_of_speech) do
    # TODO
    (entries || [])
    |> Enum.reduce([], fn %{"sense" => senses} = entry, acc ->
      senses =
        Enum.filter(senses, fn %{"pos" => pos} ->
          Enum.any?(pos, fn pos -> String.contains?(pos, part_of_speech) end)
        end)

      if senses == [] do
        acc
      else
        [%{entry | "sense" => senses} | acc]
      end
    end)
    |> :lists.reverse()
  end

  defp entry_content(%{entry: entry} = assigns) do
    assigns = assign(assigns, meanings: extract_meanings(entry))

    ~H"""
    <ul class="list-disc px-4">
      <li :for={meanings <- @meanings}>
        <%= for meaning <- Enum.intersperse(meanings, "; ") do %>
          <%= meaning %>
        <% end %>
      </li>
    </ul>
    """
  end

  defp extract_reading([%{"r_ele" => [%{"reb" => reading} | _]} | _]), do: reading
  defp extract_reading([]), do: nil

  defp extract_meanings(%{"sense" => senses}) do
    Enum.map(senses, fn %{"gloss" => meanings} -> meanings end)
  end

  alias M.Kanjis

  @impl true
  def handle_params(%{"sentence" => sentence}, _uri, socket) do
    segments = Kanjis.segment_sentence(sentence, entry: true)
    socket = assign(socket, segments: segments)
    {:noreply, socket}
  end

  defp segment_class(%{"part_of_speech" => "名詞"}), do: "text-blue-400"
  defp segment_class(%{"part_of_speech" => "助詞"}), do: "text-red-400"
  defp segment_class(%{"part_of_speech" => "動詞"}), do: "text-green-400"
  defp segment_class(%{"part_of_speech" => "形容詞"}), do: "text-pink-400"
  defp segment_class(%{"part_of_speech" => "連体詞"}), do: "text-pink-400"
  defp segment_class(%{"part_of_speech" => "助動詞"}), do: "text-yellow-400"
  defp segment_class(%{"part_of_speech" => "副詞"}), do: "text-sky-400"
  defp segment_class(%{"part_of_speech" => "フィラー"}), do: "text-gray-400"
  defp segment_class(%{"part_of_speech" => "記号"}), do: "text-gray-400"

  defp segment_class(%{"part_of_speech" => other}) do
    Logger.error("unexpected part_of_speech: #{other}")
    "text-gray-400"
  end

  defp part_of_speech_eng("名詞"), do: "noun"
  defp part_of_speech_eng("助詞"), do: "particle"
  defp part_of_speech_eng("動詞"), do: "verb"
  defp part_of_speech_eng("形容詞"), do: "adjective"
  defp part_of_speech_eng("助動詞"), do: "auxiliary verb"
  defp part_of_speech_eng("副詞"), do: "adverb"
  defp part_of_speech_eng("連体詞"), do: "adnominal adjective"
  defp part_of_speech_eng(_other), do: nil
end
