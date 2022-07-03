defmodule MWeb.KanjiLive do
  use MWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-4 max-w-screen-xl mx-auto">
      <div class="text-3xl text-center"><%= @word %></div>
      <div class="mt-4 flex -mx-2 flex-wrap">
      <%= for kanji <- @kanjis do %>
        <.kanji_info kanji={kanji} />
      <% end %>
      </div>
    </div>
    """
  end

  defp kanji_info(%{kanji: kanji} = assigns) do
    jlpt =
      case kanji.jlpt_full do
        <<level::2-bytes, _rest::bytes>> -> level
        _other -> nil
      end

    # TOOD move to preprocessor
    ons = (kanji.reg_on || "") |> String.split("、", trim: true) |> Enum.map(&String.trim/1)
    kuns = (kanji.reg_kun || "") |> String.split("、", trim: true) |> Enum.map(&String.trim/1)

    assigns = assign(assigns, jlpt: jlpt, ons: ons, kuns: kuns)

    ~H"""
    <div class="p-2 w-full md:w-1/2 lg:w-1/3">
      <div class="p-4 bg-gray-50 border border-gray-200 dark:border-none dark:bg-zinc-700 rounded h-full">
        <h3 class="flex items-center justify-between">
          <span class="text-2xl"><%= @kanji.kanji %></span>
          <div class="text-sm text-gray-400 text-right">
            <%= if @jlpt do %>
              <div><%= @jlpt %></div>
            <% end %>
            <%= if @kanji.frequency do %>
              <div>freq:<%= @kanji.frequency %></div>
            <% end %>
          </div>
        </h3>

        <dl class="mt-2">
          <div>
            <dt class="inline text-sm text-gray-500 dark:text-gray-300">radical:</dt>
            <%= live_patch to: Routes.kanji_path(MWeb.Endpoint, :radical, @kanji.radical) do %>
              <dd class="text-green-600 dark:text-green-300 inline hover:underline underline-offset-2 decoration-2"><%= @kanji.radical %><%= if @kanji.radvar do %> (<%= @kanji.radvar %>)<% end %></dd>
            <% end %>
          </div>

          <%= if @kanji.phonetic do %>
          <div>
            <dt class="inline text-sm text-gray-500 dark:text-gray-300">phonetic:</dt>
            <%= live_patch to: Routes.kanji_path(MWeb.Endpoint, :phonetic, @kanji.phonetic) do %>
              <dd class="text-sky-600 dark:text-sky-300 inline hover:underline underline-offset-2 decoration-2"><%= @kanji.phonetic %></dd>
            <% end %>
          </div>
          <% end %>

          <%= if @kanji.reg_on do %>
          <div>
            <dt class="inline text-sm text-gray-500 dark:text-gray-300">on:</dt>
            <dd class="text-yellow-600 dark:text-yellow-300 inline">
              <%= for on <- @ons do %>
                <%= live_patch on, to: Routes.kanji_path(MWeb.Endpoint, :on, trim_on(on)), class: "hover:underline underline-offset-2 decoration-2" %>
              <% end %>
            </dd>
          </div>
          <% end %>

          <%= if @kanji.reg_kun do %>
          <div>
            <dt class="inline text-sm text-gray-500 dark:text-gray-300">kun:</dt>
            <dd class="text-red-600 dark:text-red-300 inline">
              <%= for kun <- @kuns do %>
                <%= live_patch kun, to: Routes.kanji_path(MWeb.Endpoint, :kun, trim_kun(kun)), class: "hover:underline underline-offset-2 decoration-2" %>
              <% end %>
            </dd>
          </div>
          <% end %>

          <%= if @kanji.compact_meaning do %>
          <div>
            <dt class="inline text-sm text-gray-500 dark:text-gray-300">meanings:</dt>
            <dd class="text-green-600 dark:text-green-300 inline"><%= String.replace(@kanji.compact_meaning, ";", ", ") %></dd>
          </div>
          <% end %>
        </dl>
      </div>
    </div>
    """
  end

  @impl true
  def handle_params(%{"word" => word}, _uri, socket) do
    {:noreply, socket |> assign(word: word) |> fetch_kanji()}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket |> assign(word: nil, page_title: "", kanjis: [])}
  end

  defp fetch_kanji(socket) do
    alias M.Kanjis
    word = socket.assigns.word

    kanjis =
      case socket.assigns.live_action do
        :word -> Kanjis.fetch_kanjis_for_word(word)
        :radical -> Kanjis.fetch_kanjis_for(radical: word)
        :phonetic -> Kanjis.fetch_kanjis_for(phonetic: word)
        # :on -> Kanjis.fetch_kanjis_for_on(word)
        :on -> Kanjis.fetch_kanjis_like(:reg_on, word)
        :kun -> Kanjis.fetch_kanjis_like(:reg_kun, word)
      end

    assign(socket, page_title: word, kanjis: kanjis)
  end

  defp trim_kun(kun) do
    String.trim(hd(String.split(kun, "（")))
  end

  defp trim_on(on) do
    String.trim_trailing(on, "*")
  end
end
