defmodule MWeb.KanjiLive do
  use MWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket, temporary_assigns: [kanjis: [], words: []]}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-4 max-w-screen-xl mx-auto">
      <div class="text-3xl text-center"><%= @word %><%= if @word_info do %> <span class="text-gray-400">(<%= @word_info.reading %>)</span><% end %></div>

      <%= if @word_info do %>
      <div class="mt-2 flex space-x-4 justify-center text-gray-400">
        <div class="text-green-600 dark:text-green-300"><%= @word_info.meaning %></div>
      </div>
      <% end %>

      <div class="mt-4 flex -mx-2 flex-wrap justify-center">
      <%= for kanji <- @kanjis do %><.kanji_card kanji={kanji} /><% end %>
      </div>

      <div class="mt-4 flex -mx-2 flex-wrap">
      <%= for word <- @words do %><.word_card word={word} /><% end %>
      </div>
    </div>
    """
  end

  defp kanji_card(%{kanji: kanji} = assigns) do
    jlpt =
      case kanji.jlpt_full do
        <<level::2-bytes, _rest::bytes>> -> level
        _other -> nil
      end

    assigns = assign(assigns, jlpt: jlpt)
    assigns = assign(assigns, meaning: kanji.compact_meaning || kanji.meaning)

    ~H"""
    <div class="p-2 w-full md:w-1/2 lg:w-1/3">
      <div class="p-4 bg-gray-50 border border-gray-200 dark:border-none dark:bg-zinc-700 rounded h-full">
        <h3 class="flex items-center justify-between">
          <span class="text-2xl"><%= @kanji.kanji %></span>
          <div class="ml-4 text-sm text-gray-400 text-right">
            <%= if @jlpt do %>
              <div><%= @jlpt %></div>
            <% end %>
            <%= if @kanji.frequency do %>
              <div>freq:<%= @kanji.frequency %></div>
            <% end %>
          </div>
        </h3>

        <dl class="mt-2">
          <.info_point title="radical" color="text-green-600 dark:text-green-300">
            <.link navigate={kanji_path(:radical, @kanji.radical)} class="hover:underline underline-offset-2 decoration-2">
              <%= @kanji.radical %><%= if @kanji.radvar do %> (<%= @kanji.radvar %>)<% end %>
            </.link>
          </.info_point>

          <%= if @kanji.phonetic do %>
          <.info_point title="phonetic" color="text-sky-600 dark:text-sky-300">
            <.link href={kanji_path(:phonetic, @kanji.phonetic)} class="hover:underline underline-offset-2 decoration-2"><%= @kanji.phonetic %></.link>
          </.info_point>
          <% end %>

          <%= if @kanji.reg_on && @kanji.reg_on != [] do %>
          <.info_point title="on" color="text-yellow-600 dark:text-yellow-300">
            <%= for on <- @kanji.reg_on do %>
              <.link navigate={kanji_path(:on, trim_on(on))} class="hover:underline underline-offset-2 decoration-2"><%= on %></.link>
            <% end %>
          </.info_point>
          <% end %>

          <%= if @kanji.reg_kun && @kanji.reg_kun != [] do %>
          <.info_point title="kun" color="text-red-600 dark:text-red-300">
            <%= for kun <- @kanji.reg_kun do %>
              <.link navigate={kanji_path(:kun, trim_on(trim_kun(kun)))} class="hover:underline underline-offset-2 decoration-2"><%= kun %></.link>
            <% end %>
          </.info_point>
          <% end %>

          <%= if @meaning && @meaning != [] do %>
          <.info_point title="meanings" color="text-green-600 dark:text-green-300">
            <%= for meaning <- @meaning do %>
              <.link navigate={kanji_path(:meaning, meaning)} class="hover:underline underline-offset-2 decoration-2"><%= meaning %></.link>
            <% end %>
          </.info_point>
          <% end %>
        </dl>
      </div>
    </div>
    """
  end

  defp word_card(assigns) do
    ~H"""
    <div class="p-2 w-full md:w-1/2 lg:w-1/3">
      <div class="p-4 bg-gray-50 border border-gray-200 dark:border-none dark:bg-zinc-700 rounded h-full">
        <h3 class="flex items-center justify-between">
          <.link navigate={kanji_path(:word, @word.expression)} class="text-2xl hover:underline underline-offset-4 decoration-2"><%= @word.expression %></.link>
          <div class="ml-4 text-xs text-gray-400 text-right"><%= @word.tags %></div>
        </h3>
        <dl class="mt-2">
          <.info_point title="reading" color="text-sky-600 dark:text-sky-300"><%= @word.reading %></.info_point>
          <.info_point title="meaning" color="text-green-600 dark:text-green-300"><%= @word.meaning %></.info_point>
        </dl>
      </div>
    </div>
    """
  end

  defp info_point(assigns) do
    ~H"""
    <div>
      <dt class="inline text-sm text-gray-500 dark:text-gray-300"><%= @title %>:</dt>
      <dd class={@color <> " inline"}><%= render_slot(@inner_block) %></dd>
    </div>
    """
  end

  defp kanji_path(action, value) do
    Routes.kanji_path(MWeb.Endpoint, action, value)
  end

  alias M.Kanjis

  @impl true
  def handle_params(%{"word" => word}, _uri, socket) do
    word_info = Kanjis.jlpt_get_word(word)

    socket =
      socket
      |> assign(word: word, word_info: word_info, page_title: word, words: [])
      |> fetch_kanji()

    {:noreply, socket}
  end

  def handle_params(_params, _uri, socket) do
    words = Kanjis.jlpt_list_words()
    socket = assign(socket, word: nil, word_info: nil, page_title: "", kanjis: [], words: words)
    {:noreply, socket}
  end

  defp fetch_kanji(socket) do
    word = socket.assigns.word

    kanjis =
      case socket.assigns.live_action do
        :word -> Kanjis.fetch_kanjis_for_word(word)
        :radical -> Kanjis.fetch_kanjis_for(radical: word)
        :phonetic -> Kanjis.fetch_kanjis_for(phonetic: word)
        :on -> Kanjis.fetch_kanjis_for_on(word)
        :kun -> Kanjis.fetch_kanjis_for_kun(word)
        :meaning -> Kanjis.fetch_kanjis_for_meaning(word)
      end

    assign(socket, kanjis: kanjis)
  end

  defp trim_kun(kun) do
    String.trim(hd(String.split(kun, "（")))
  end

  defp trim_on(on) do
    String.trim_trailing(on, "*")
  end
end
