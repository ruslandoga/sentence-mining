defmodule MWeb.Router do
  use MWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MWeb do
    pipe_through :browser

    live "/", KanjiLive, :index
    live "/:word", KanjiLive, :word
    live "/radical/:word", KanjiLive, :radical
    live "/phonetic/:word", KanjiLive, :phonetic
    live "/on/:word", KanjiLive, :on
    live "/kun/:word", KanjiLive, :kun
    live "/meaning/:word", KanjiLive, :meaning
    live "/sentence/:sentence", SentenceLive, :sentence
  end

  scope "/api", MWeb do
    pipe_through(:api)
    post "/bot/:token", BotController, :webhook
  end
end
