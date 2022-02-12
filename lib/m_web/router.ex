defmodule MWeb.Router do
  use MWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api/bot", MWeb do
    pipe_through :api
    post "/:token", BotController, :webhook
  end
end
