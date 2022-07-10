defmodule MWeb.SentenceLive do
  use MWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, temporary_assigns: [segments: [], sentence: nil]}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen lg:flex lg:items-center lg:justify-center">
      <div class="text-2xl p-6 max-w-screen-xl mx-auto">
        <%= for {segment, idx} <- Enum.with_index(@segments) do %>
          <span id={"segment-#{idx}"} class={segment_class(segment)} {tippy(segment)}><%= segment["surface_form"] %></span>
        <% end %>
      </div>
    </div>
    """
  end

  alias M.Kanjis

  @impl true
  def handle_params(%{"sentence" => sentence}, _uri, socket) do
    segments =
      sentence
      |> Kanjis.segment_sentence()
      |> Enum.map(fn %{"lexical_form" => word} = segment ->
        Map.put(segment, "word", Kanjis.get_word(word))
      end)

    socket = assign(socket, sentence: sentence, segments: segments)
    {:noreply, socket}
  end

  defp segment_class(%{"part_of_speech" => "名詞"}), do: "text-blue-400"
  defp segment_class(%{"part_of_speech" => "助詞"}), do: "text-red-400"
  defp segment_class(%{"part_of_speech" => "動詞"}), do: "text-green-400"
  defp segment_class(%{"part_of_speech" => "形容詞"}), do: "text-pink-400"
  defp segment_class(%{"part_of_speech" => "連体詞"}), do: "text-pink-400"
  defp segment_class(%{"part_of_speech" => "助動詞"}), do: "text-yellow-400"
  defp segment_class(%{"part_of_speech" => "副詞"}), do: "text-sky-400"
  defp segment_class(%{"part_of_speech" => "記号"}), do: "text-gray-400"

  defp part_of_speech_eng("名詞"), do: "noun"
  defp part_of_speech_eng("助詞"), do: "particle"
  defp part_of_speech_eng("動詞"), do: "verb"
  defp part_of_speech_eng("形容詞"), do: "adjective"
  defp part_of_speech_eng("助動詞"), do: "auxiliary verb"
  defp part_of_speech_eng("副詞"), do: "adverb"
  defp part_of_speech_eng("連体詞"), do: "adnominal adjective"
  defp part_of_speech_eng(_other), do: nil

  defp tippy(%{"part_of_speech" => part_of_speech, "lexical_form" => lexical_form, "word" => word}) do
    if part_of_speech = part_of_speech_eng(part_of_speech) do
      data =
        if word do
          %{
            "part_of_speech" => part_of_speech,
            "lexical_form" => lexical_form,
            "word" => Map.take(word, [:meaning, :reading])
          }
        else
          %{"part_of_speech" => part_of_speech}
        end

      %{data_tippy: Jason.encode!(data), phx_hook: "TippyHook"}
    else
      %{}
    end
  end
end
