defmodule SevensageassignmentWeb.FirstYearRankingsLive do
  use SevensageassignmentWeb, :live_view
  # Your actual context module
  alias Sevensageassignment.FirstYearRankings

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        query: "",
        search_results: [],
        selected_school_name: nil,
        # Latest year data
        selected_ranking_data: nil,
        show_trend_chart: false,
        show_rank_chart: false,
        show_gre_chart: false,
        search_active: false
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("search_school", %{"value" => query}, socket) do
    trimmed_query = String.trim(query)
    search_active = trimmed_query != ""

    search_results =
      if search_active do
        FirstYearRankings.search_schools(trimmed_query)
      else
        []
      end

    socket =
      assign(socket,
        query: query,
        search_results: search_results,
        search_active: search_active
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_school", %{"name" => school_name}, socket) do
    latest_data = FirstYearRankings.get_latest_ranking_by_school(school_name)
    trend_data = FirstYearRankings.get_rankings_by_school(school_name)

    # Prepare data for all charts
    trend_chart_js = prepare_trend_chart_data(trend_data)
    rank_chart_js = prepare_rank_chart_data(trend_data)
    gre_chart_js = prepare_gre_chart_data(trend_data)

    # Encode only if data exists
    trend_chart_json = if trend_chart_js, do: Jason.encode!(trend_chart_js), else: nil
    rank_chart_json = if rank_chart_js, do: Jason.encode!(rank_chart_js), else: nil
    gre_chart_json = if gre_chart_js, do: Jason.encode!(gre_chart_js), else: nil

    # Update assigns
    socket =
      assign(socket,
        query: "",
        search_results: [],
        selected_school_name: school_name,
        selected_ranking_data: latest_data,
        show_trend_chart: !is_nil(trend_chart_json),
        show_rank_chart: !is_nil(rank_chart_json),
        show_gre_chart: !is_nil(gre_chart_json),
        search_active: false
      )

    # Push separate events for each chart
    socket =
      socket
      |> push_event("update_trend_chart", %{data: trend_chart_json})
      |> push_event("update_rank_chart", %{data: rank_chart_json})
      |> push_event("update_gre_chart", %{data: gre_chart_json})

    {:noreply, socket}
  end

  defp error(assigns) do
    ~H"""
    <p :if={Map.get(assigns, :if, true)} class="mt-1 text-sm text-red-600">
      {render_slot(@inner_block)}
    </p>
    """
  end

  defp prepare_trend_chart_data(trend_data) do
    years = Enum.map(trend_data, &to_string(&1.first_year_class))
    lsat_values = Enum.map(trend_data, &(Map.get(&1, :l50) |> ensure_numeric_or_null()))
    gpa_values = Enum.map(trend_data, &(Map.get(&1, :g50) |> ensure_numeric_or_null()))

    valid_lsat = Enum.count(lsat_values, &(!is_nil(&1))) >= 2
    valid_gpa = Enum.count(gpa_values, &(!is_nil(&1))) >= 2

    if valid_lsat or valid_gpa do
      %{
        labels: years,
        datasets: [
          %{
            label: "Median LSAT",
            data: lsat_values,
            borderColor: "rgb(54, 162, 235)",
            backgroundColor: "rgba(54, 162, 235, 0.5)",
            tension: 0.1,
            yAxisID: "y"
          },
          %{
            label: "Median GPA",
            data: Enum.map(gpa_values, &decimal_to_float_or_nil/1),
            borderColor: "rgb(255, 99, 132)",
            backgroundColor: "rgba(255, 99, 132, 0.5)",
            tension: 0.1,
            yAxisID: "y1"
          }
        ]
      }
    else
      nil
    end
  end

  defp prepare_rank_chart_data(trend_data) do
    years = Enum.map(trend_data, &to_string(&1.first_year_class))
    rank_values = Enum.map(trend_data, &(Map.get(&1, :rank) |> rank_to_numeric()))
    valid_ranks = Enum.count(rank_values, &(!is_nil(&1)))

    if valid_ranks >= 2 do
      %{
        labels: years,
        datasets: [
          %{
            label: "Rank",
            data: rank_values,
            borderColor: "rgb(75, 192, 192)",
            backgroundColor: "rgba(75, 192, 192, 0.5)",
            tension: 0.1,
            yAxisID: "yRank"
          }
        ]
      }
    else
      nil
    end
  end

  defp prepare_gre_chart_data(trend_data) do
    years = Enum.map(trend_data, &to_string(&1.first_year_class))

    gre_median_fields = [
      {:gre50v, "Median V", "rgb(255, 99, 132)"},
      {:gre50q, "Median Q", "rgb(75, 0, 130)"},
      {:gre50w, "Median W", "rgb(54, 162, 235)"}
    ]

    datasets =
      Enum.map(gre_median_fields, fn {field_key, label, color} ->
        # Extract data points for the specific median field
        data_points =
          Enum.map(
            trend_data,
            &(Map.get(&1, field_key) |> ensure_numeric_or_null() |> decimal_to_float_or_nil())
          )

        # Assign appropriate Y-axis based on the type (Writing vs V/Q)
        y_axis = if String.ends_with?(label, "W"), do: "yGreW", else: "yGreVQ"
        # Create the dataset map
        %{
          label: label,
          data: data_points,
          borderColor: color,
          backgroundColor: "#{String.replace(color, ")", ", 0.2)")}",
          tension: 0.1,
          yAxisID: y_axis,
          pointRadius: 3
        }
      end)

    # Check if any median GRE data point exists across the 3 datasets
    has_any_median_gre_data = Enum.any?(datasets, fn ds -> Enum.any?(ds.data, &(!is_nil(&1))) end)
    # Check if at least one median dataset has enough points to draw a line
    has_enough_points = Enum.any?(datasets, fn ds -> Enum.count(ds.data, &(!is_nil(&1))) >= 2 end)

    # Return data only if there's some data and at least one line can be drawn
    if has_any_median_gre_data && has_enough_points do
      %{labels: years, datasets: datasets}
    else
      # Not enough valid median GRE data to plot
      nil
    end
  end

  defp display_data(nil), do: "N/A"
  defp display_data(""), do: "N/A"

  defp display_data(%Decimal{} = value) do
    precision = if Decimal.compare(value, Decimal.new(10)) == :lt, do: 2, else: 1
    Decimal.round(value, precision) |> Decimal.to_string()
  rescue
    _ -> "N/A"
  end

  defp display_data(value) when is_float(value), do: Float.round(value, 2)
  defp display_data(value), do: value

  defp has_gre_data?(data, category) when category in [:v, :q, :w] do
    prefix = "gre"
    suffixes = ["25", "50", "75"]
    keys = Enum.map(suffixes, &String.to_atom("#{prefix}#{&1}#{category}"))

    Enum.any?(keys, fn key ->
      val = Map.get(data, key)
      !(is_nil(val) || val == "")
    end)
  end

  defp ensure_numeric_or_null(val) when is_integer(val), do: val
  defp ensure_numeric_or_null(%Decimal{} = val), do: val
  defp ensure_numeric_or_null(_), do: nil

  defp decimal_to_float_or_nil(%Decimal{} = dec), do: Decimal.to_float(dec)
  defp decimal_to_float_or_nil(int) when is_integer(int), do: int
  defp decimal_to_float_or_nil(_), do: nil

  defp rank_to_numeric(rank) when is_integer(rank), do: rank

  defp rank_to_numeric(rank_str) when is_binary(rank_str) do
    case Integer.parse(rank_str) do
      {num, ""} -> num
      {num, "-"} -> num
      {num, _rest} -> num
      :error -> if String.downcase(rank_str) == "unranked", do: 200, else: nil
    end
  rescue
    _ -> nil
  end

  defp rank_to_numeric(_), do: nil
end
