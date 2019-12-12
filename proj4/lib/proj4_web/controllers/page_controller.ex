defmodule Proj4Web.PageController do
  use Proj4Web, :controller

  def index(conn, _params) do
    render(conn, "home_page.html")
  end
end
