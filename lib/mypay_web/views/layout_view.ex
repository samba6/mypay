defmodule MyPayWeb.LayoutView do
  use MyPayWeb, :view

  require EEx

  alias MyPayWeb.Endpoint

  @index_js_path "commons.js"
  @index_css_path "commons.css"


  EEx.function_from_string(
    :def,
    :css_tag_eex,
    ~s(<link rel="stylesheet" type="text/css" href="<%= @href %>" media="screen,projection" />),
    [:assigns]
  )

  EEx.function_from_string(
    :def,
    :js_tag_eex,
    ~s(<script src="<%= @src %>"></script>),
    [:assigns]
  )

  EEx.function_from_string(
    :def,
    :webpack_server_url,
    "http://localhost:4019/<%= @path1 %>/<%= @path2 %>",
    [:assigns]
  )

  # EXPORTS FOR TEST
  @spec index_css_path() :: <<_::88>>
  def index_css_path, do: @index_css_path

  @spec index_js_path() :: <<_::80>>
  def index_js_path, do: @index_js_path
  # / EXPORTS FOR TEST

  # ---------------------------------------PAGE TOP MENU---------------------

  @spec top_menu(module, map()) :: Plug.Conn.t() | String.t()
  def top_menu(view_module, %{} = assigns) do
    case :erlang.function_exported(view_module, :top_menu, 1) do
      true ->
        apply(view_module, :top_menu, [assigns])

      _ ->
        ""
    end
  end

  # -------------------------------------------PAGE JS---------------------

  def page_js(path, raw? \\ :raw)

  def page_js(nil, _raw?), do: ""

  def page_js(:index, raw?),
    do:
      :js
      |> js_css_src(@index_js_path)
      |> html_tag(raw?)

  def page_js(path, raw?),
    do:
      :js
      |> js_css_src(path)
      |> html_tag(raw?)

  # -------------------------------------------PAGE CSS---------------------

  def page_css(path, raw? \\ :raw)

  def page_css(nil, _raw?), do: ""

  def page_css(:index, raw?) do
    path =
      case get_frontend_env(:asset) do
        :prod -> @index_css_path
        :dev -> @index_js_path
      end

    js_css_src(:css, path)
    |> html_tag(raw?)
  end

  def page_css(path, raw?),
    do:
      js_css_src(:css, path)
      |> html_tag(raw?)

  defp html_tag({:css, href}, raw?) when is_binary(href),
    do:
      css_tag_eex(href: href)
      |> html_tag(raw?)

  defp html_tag({:css_js, src}, raw?) when is_binary(src),
    do: html_tag({:js, src}, raw?)

  defp html_tag({:js, src}, raw?) when is_binary(src),
    do:
      js_tag_eex(src: src)
      |> html_tag(raw?)

  defp html_tag(html, :raw) when is_binary(html), do: raw(html)
  defp html_tag(html, _), do: html

  # ------------------------------UTILITIES--------------------------------

  def js_css_src(_, nil), do: nil

  def js_css_src(type, href) when is_binary(href),
    do:
      :asset
      |> get_frontend_env()
      |> js_css_src(type, href)

  def js_css_src(:dev, :css, src) when is_binary(src) do
    src = String.replace(src, ~r/\.css$/, ".js")
    src = webpack_server_url(path1: "css", path2: src)

    {:css_js, src}
  end

  def js_css_src(:dev, :js, src) when is_binary(src),
    do: {:js, webpack_server_url(path1: "js", path2: src)}

  def js_css_src(:prod, :css, href) when is_binary(href),
    do: {:css, Endpoint.static_path("/css/#{String.trim(href, "/")}")}

  def js_css_src(:prod, :js, src) when is_binary(src),
    do: {:js, Endpoint.static_path("/js/#{String.trim(src, "/")}")}

  @doc ~S"""
    For the App shell used in offline mode, the view_module argument will be
    :true and we thus render no child template because the rendering will be
    done client side.
  """
  @spec render_child_main_child_template(true | Atom.t(), any(), any()) :: any()
  def render_child_main_child_template(true, _, _), do: ""

  def render_child_main_child_template(view_module, view_template, assigns),
    do: render(view_module, view_template, assigns)

  @spec get_frontend_env(key :: Atom.t()) :: Atom.t()
  def get_frontend_env(key),
    do:
      :mypay
      |> Application.get_env(:frontend)
      |> get_frontend_env(key)

  @spec get_frontend_env(env :: nil | keyword(), key :: Atom.t()) :: Atom.t()
  def get_frontend_env(nil, _), do: nil
  def get_frontend_env([], _), do: nil

  def get_frontend_env(env, key) when is_list(env),
    do: Keyword.fetch!(env, key)
end
