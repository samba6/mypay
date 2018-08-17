defmodule BurdaWeb.IndexController do
  use Phoenix.Controller

  # alias BurdaWeb.Schema
  # alias BurdaWeb.Query.Shift, as: Query
  alias Burda.Shift.Api
  alias BurdaWeb.LayoutView
  alias BurdaWeb.IndexView

  @main_css_handlebar "{{{ mainCss }}}"
  @main_js_handlebar "{{{ mainJs }}}"
  @index_css_path LayoutView.index_css_path()
  @index_js_path LayoutView.index_js_path()

  @page_js "routes/index.js"
  @page_css "routes/index.css"
  @page_title_handlebar "{{ pageTitle }}"
  @page_main_css_handlebar "{{{ pageMainCss }}}"
  @page_other_css_handlebar "{{{ pageOtherCss }}}"
  @page_main_js_handlebar "{{{ pageMainJs }}}"
  @page_other_js_handlebar "{{{ pageOtherJs }}}"
  @page_main_content_handlebar "{{{ pageMainContent }}}"
  @page_top_menu_handlebar "{{{ pageTopMenu }}}"
  @app_html "app.html"
  @index_html "index.html"
  @menu_html "menu.html"
  @shift_detail "_shift-detail.html"
  @shift_earnings_summary "_shift.earnings.summary.html"

  @index_offline_templates [
    index_offline_template: "indexTemplate",
    index_offline_menu_template: "indexMenuTemplate",
    app_shell_offline_template: "appShellTemplate",
    shift_detail_offline_template: "shiftDetailTemplate",
    shift_earnings_summary_offline_template: "shiftEarningSummaryTemplate"
  ]

  plug(:assign_defaults)

  @spec index(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def index(conn, _) do
    today = conn.assigns.today

    render(
      conn,
      @index_html,
      all_shifts: Api.shifts_for_current_month(today.year, today.month),
      new_shift_path: BurdaWeb.Router.Helpers.shift_path(conn, :new)
    )
  end

  def index_skeleton(conn, _params) do
    conn
    |> put_resp_header("content-type", "text/html")
    |> resp(200, index_offline_template())
  end

  def assign_defaults(conn, _) do
    today = Date.utc_today()

    merge_assigns(
      conn,
      page_js: @page_js,
      page_css: @page_css,
      current_month: Timex.format!(today, "{Mshort}/{YYYY}"),
      today: today
    )
  end

  def index_offline_template,
    do: Phoenix.View.render_to_string(IndexView, @index_html, [])

  def index_offline_menu_template,
    do: Phoenix.View.render_to_string(IndexView, @menu_html, [])

  def shift_detail_offline_template,
    do: Phoenix.View.render_to_string(IndexView, @shift_detail, [])

  def shift_earnings_summary_offline_template,
    do: Phoenix.View.render_to_string(IndexView, @shift_earnings_summary, [])

  def index_offline_template_assigns,
    do: %{
      pageTitle: "Shift Times",
      pageMainCss: LayoutView.page_css(@page_css, nil),
      pageMainJs: LayoutView.page_js(@page_js, nil),
      mainCss: LayoutView.page_css(@index_css_path, nil),
      mainJs: LayoutView.page_js(@index_js_path, nil),
      cacheStatic:
        [
          LayoutView.js_css_src(:css, @page_css),
          LayoutView.js_css_src(:js, @page_js)
        ]
        |> Enum.map(fn {_, path} -> path end)
    }

  def get_index_offline_template_assigns(conn, _),
    do:
      conn
      |> json(index_offline_template_assigns())

  def index_offline_templates, do: @index_offline_templates

  def app_shell_offline_template,
    do:
      Phoenix.View.render_to_string(
        BurdaWeb.LayoutView,
        @app_html,
        view_module_: true,
        page_title: @page_title_handlebar,
        page_main_css_handlebar: @page_main_css_handlebar,
        page_other_css_handlebar: @page_other_css_handlebar,
        page_main_js_handlebar: @page_main_js_handlebar,
        page_other_js_handlebar: @page_other_js_handlebar,
        page_main_content_handlebar: @page_main_content_handlebar,
        page_top_menu_handlebar: @page_top_menu_handlebar,
        main_css_handlebar: @main_css_handlebar,
        main_js_handlebar: @main_js_handlebar
      )
end
