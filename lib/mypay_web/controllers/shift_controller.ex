defmodule MyPayWeb.ShiftController do
  use Phoenix.Controller

  @dialyzer {:no_return, metas: 0, new: 2}

  alias MyPayWeb.LayoutView
  alias MyPayWeb.ShiftView

  @new_shift_html "new-shift.html"
  @page_css "routes/shift.css"
  @page_js "routes/shift.js"
  @new_form_css_path "components/new-meta-form.css"

  @months_of_year [
                    "Jan",
                    "Feb",
                    "Mar",
                    "Apr",
                    "May",
                    "Jun",
                    "Jul",
                    "Aug",
                    "Sep",
                    "Oct",
                    "Nov",
                    "Dec"
                  ]
                  |> Enum.with_index(1)
                  |> Enum.map(fn {m, index} ->
                    {
                      index,
                      %{
                        display: m,
                        selected: ""
                      }
                    }
                  end)
                  |> Enum.into(%{})

  @days_of_month 1..31
                 |> Enum.map(
                   &{&1,
                    %{
                      display: String.pad_leading("#{&1}", 2, "0"),
                      selected: ""
                    }}
                 )
                 |> Enum.into(%{})

  @metas_query """
  query GetAllMetasForShiftController($metaInput: GetMetaInput) {
    metas(meta: $metaInput) {
      id
      _id
      breakTimeSecs
      payPerHr
      nightSupplPayPct
      sundaySupplPayPct
      schemaType
    }
  }
  """

  @metas_query_variables %{
    "metaInput" => %{
      "orderBy" => %{
        "id" => "DESC"
      }
    }
  }

  plug(:assign_defaults)

  @spec new(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def new(conn, _params) do
    now = Timex.now(Timex.Timezone.Local.lookup())

    months_of_year =
      Map.update!(
        @months_of_year,
        now.month,
        &Map.put(&1, :selected, "selected")
      )

    days_of_month =
      Map.update!(
        @days_of_month,
        now.day,
        &Map.put(&1, :selected, "selected")
      )

    year = now.year

    years =
      -4..-1
      |> Enum.map(&{&1 + year, ""})
      |> Enum.concat([{year, "selected"}])

    render(
      conn,
      @new_shift_html,
      metas: metas(),
      year_default: year,
      months_of_year: months_of_year,
      days_of_month: days_of_month,
      years: years,
      page_title: "New Shift",
      go_back_url: go_back_url(conn)
    )
  end

  @doc false
  def new_offline_template_assigns,
    do: %{
      page_title: "New Shift",
      page_main_css: LayoutView.page_css(@page_css, nil),
      page_main_js: LayoutView.page_js(@page_js, nil),
      page_other_css: LayoutView.page_css(@new_form_css_path, nil)
    }

  @doc false
  def new_offline_templates do
    [
      {
        Phoenix.View.render_to_string(ShiftView, @new_shift_html, []),
        "newShiftTemplate"
      },
      {
        Phoenix.View.render_to_string(ShiftView, "_menu.html", []),
        "partials/newShiftMenuTemplate"
      },
      {
        Phoenix.View.render_to_string(ShiftView, "_new-shift-date.html", []),
        "newShiftDateTemplate"
      },
      {
        Phoenix.View.render_to_string(
          ShiftView,
          "_new-shift-metas-select.html",
          []
        ),
        "newShiftMetasSelectTemplate"
      },
      {
        Phoenix.View.render_to_string(
          MyPayWeb.MetaView,
          "new-meta.html",
          []
        ),
        "newMetaFormTemplate"
      }
    ]
  end

  @spec assign_defaults(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def assign_defaults(conn, _),
    do:
      merge_assigns(
        conn,
        page_css: @page_css,
        page_js: @page_js,
        preload_resources: [
          LayoutView.js_css_src(:css, @new_form_css_path)
        ]
      )

  defp metas do
    case MyPayWeb.Schema.run_query(@metas_query, @metas_query_variables) do
      {:ok, %{errors: _}} ->
        []

      {:ok, %{data: %{"metas" => [latest_meta | rest_metas]}}} ->
        [
          Map.put(latest_meta, "selected", "selected")
          | Enum.map(rest_metas, &Map.put(&1, "selected", ""))
        ]
        |> Enum.map(
          &Map.update!(
            &1,
            "breakTimeSecs",
            fn v -> Float.round(v / 60, 1) end
          )
        )

      _ ->
        []
    end
  end

  def go_back_url(conn) do
    index_path = MyPayWeb.Router.Helpers.index_path(conn, :index)
    this_path = MyPayWeb.Router.Helpers.shift_path(conn, :new)

    case get_req_header(conn, "referer") do
      [url | _] ->
        if(url == this_path, do: index_path, else: url)

      _ ->
        index_path
    end
  end
end
