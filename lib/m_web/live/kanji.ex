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
      <div class="font-semibold text-2xl text-center"><%= @word %></div>
      <div class="mt-4 flex -mx-2 flex-wrap">
      <%= for kanji <- @kanjis do %>
        <.kanji_info kanji={kanji} />
      <% end %>
      </div>
    </div>
    """
  end

  defp kanji_info(assigns) do
    ~H"""
    <div class="p-2 w-full md:w-1/2 lg:w-1/3">
      <div class="p-4 bg-gray-50 border border-gray-200 dark:border-none dark:bg-zinc-700 rounded h-full">
        <h3 class="text-xl font-semibold"><%= @kanji.kanji %> <span class="text-sm font-normal text-gray-500 dark:text-gray-200">(freq: <%= @kanji.frequency %>)</span></h3>

        <dl class="mt-2">
          <div>
            <dt class="inline-block text-sm text-gray-500 dark:text-gray-300">radical:</dt>
            <dd class="text-green-600 dark:text-green-300 inline-block"><%= @kanji.radical %></dd>
          </div>

          <%= if @kanji.phonetic do %>
          <div>
            <dt class="inline-block text-sm text-gray-500 dark:text-gray-300">phonetic:</dt>
            <dd class="inline-block"><%= @kanji.phonetic %></dd>
          </div>
          <% end %>

          <div>
            <dt class="inline-block text-sm text-gray-500 dark:text-gray-300">on:</dt>
            <dd class="text-yellow-600 dark:text-yellow-300 inline-block"><%= @kanji.reg_on %></dd>
          </div>
          <div>
            <dt class="inline-block text-sm text-gray-500 dark:text-gray-300">kun:</dt>
            <dd class="text-red-600 dark:text-red-300 inline-block"><%= @kanji.reg_kun %></dd>
          </div>

          <%= if @kanji.compact_meaning do %>
          <div>
            <dt class="inline-block text-sm text-gray-500 dark:text-gray-300">meanings:</dt>
            <dd class="text-orange-600 dark:text-red-300 inline-block"><%= String.replace(@kanji.compact_meaning, ";", ", ") %></dd>
          </div>
          <% end %>
        </dl>
      </div>
    </div>
    """
  end

  @impl true
  def handle_params(%{"word" => word}, _uri, socket) do
    {:noreply, socket |> assign(word: word) |> fetch_word()}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket |> assign(word: nil, page_title: "", kanjis: [])}
  end

  defp fetch_word(socket) do
    word = socket.assigns.word
    kanjis = M.Kanjis.fetch_kanjis_for_word(word)
    assign(socket, page_title: word, kanjis: kanjis)
  end
end
