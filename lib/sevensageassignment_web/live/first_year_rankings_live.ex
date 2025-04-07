defmodule SevensageassignmentWeb.FirstYearRankingsLive do
  use SevensageassignmentWeb, :live_view
  alias Sevensageassignment.FirstYearRankings # Your actual context module

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        query: "",
        search_results: [],
        selected_school_name: nil,
        selected_ranking_data: nil, # Latest year data
        show_trend_chart: false,    # Flag for LSAT/GPA chart
        show_rank_chart: false,     # Flag for Rank chart
        show_gre_chart: false,      # Flag for GRE chart
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

    socket = assign(socket,
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
     socket = assign(socket,
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
     socket = push_event(socket, "update_trend_chart", %{data: trend_chart_json})
     socket = push_event(socket, "update_rank_chart", %{data: rank_chart_json})
     socket = push_event(socket, "update_gre_chart", %{data: gre_chart_json})

     {:noreply, socket}
  end


  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-6 bg-gray-50 rounded-lg shadow-md space-y-6">
      <h1 class="text-2xl font-bold text-center text-gray-800 mb-4">Law School First Year Class Data</h1>

      <div class="relative mb-6">
        <label for="school_search" class="block text-sm font-medium text-gray-700 mb-1">Search for School</label>
        <.input id="school_search" type="text" name="query" value={@query} phx-keyup="search_school" phx-debounce="300" autocomplete="off" placeholder="e.g. Harvard" class="w-full"/>
        <.error :if={@search_active && @search_results == [] && is_nil(@selected_school_name)}> No matching schools found for "<%= @query %>". </.error>
        <div :if={@search_results != []} class="absolute z-10 mt-1 w-full bg-white shadow-lg max-h-60 rounded-md py-1 text-base ring-1 ring-black ring-opacity-5 overflow-auto focus:outline-none sm:text-sm">
          <ul> <li :for={school_name <- @search_results} class="text-gray-900 cursor-pointer select-none relative py-2 pl-3 pr-9 hover:bg-sky-600 hover:text-white" phx-click="select_school" phx-value-name={school_name} phx-key={school_name}> <%= school_name %> </li> </ul>
        </div>
      </div>

      <div :if={@selected_ranking_data} class="mt-6 space-y-6 p-4 border border-gray-200 rounded-lg bg-white">
        <h2 class="text-xl font-semibold text-sky-700"> <%= @selected_ranking_data.school %> - <%= @selected_ranking_data.first_year_class %> Data (Latest Available) </h2>
        <div> <p class="text-gray-700 text-lg"> For the <%= @selected_ranking_data.first_year_class %> entering class at <%= @selected_ranking_data.school %>, the median LSAT score was <%= display_data(@selected_ranking_data.l50) %> and the median GPA was <%= display_data(@selected_ranking_data.g50) %>. </p> </div>
        <div class="overflow-x-auto"> <.data_table data={@selected_ranking_data} /> </div>

        <div class="mt-8 border-t pt-6">
           <h3 class="text-lg font-medium text-gray-800 mb-2">Median LSAT & GPA Trends</h3>
           <div :if={@show_trend_chart} id="trend-chart-wrapper" class="bg-gray-100 p-4 rounded relative h-72 md:h-96">
              <canvas id="trendChart" phx-update="ignore" phx-hook="TrendChart"></canvas>
           </div>
           <p :if={!@show_trend_chart} class="text-gray-500 text-sm mt-2"> Not enough historical data for LSAT/GPA trends. </p>
        </div>

        <div class="mt-8 border-t pt-6">
           <h3 class="text-lg font-medium text-gray-800 mb-2">Rank History</h3>
           <div :if={@show_rank_chart} id="rank-chart-wrapper" class="bg-gray-100 p-4 rounded relative h-60 md:h-96">
              <canvas id="rankChart" phx-update="ignore" phx-hook="RankChart"></canvas>
           </div>
           <div :if={@show_rank_chart} class="mt-1 text-gray-500 text-sm">Note: ranks lower than 146 are not tracked and will all be displayed as rank 147.</div>
           <p :if={!@show_rank_chart} class="text-gray-500 text-sm mt-2"> Not enough historical data for rank trend. </p>
        </div>

        <div class="mt-8 border-t pt-6">
           <h3 class="text-lg font-medium text-gray-800 mb-2">GRE Score Trends (25th/50th/75th)</h3>
           <div :if={@show_gre_chart} id="gre-chart-wrapper" class="bg-gray-100 p-4 rounded relative h-72 md:h-96">
              <canvas id="greChart" phx-update="ignore" phx-hook="GreChart"></canvas>
           </div>
           <p :if={!@show_gre_chart} class="text-gray-500 text-sm mt-2"> No historical GRE data found or not enough points to display trends. </p>
        </div>
      </div>

       <div :if={@selected_school_name && is_nil(@selected_ranking_data)} class="text-center text-gray-500 mt-6"> No ranking data found for <%= @selected_school_name %>. </div>
       <div :if={is_nil(@selected_school_name) && !@search_active && @query == ""} class="text-center text-gray-500 mt-6"> Please search for and select a school to view its data. </div>
    </div>
    """
  end

  defp data_table(assigns) do
    ~H"""
    <div class="grid lg:grid-cols-2 lg:gap-4">
      <div>
        <div class="grid sm:grid-cols-4 gap-4 text-sm mb-4">
          <div class="font-semibold text-gray-800 col-span-full sm:col-span-1">LSAT</div>
          <div class="sm:col-span-3 grid grid-cols-3 gap-4 text-gray-800">
            <div><span class="font-medium text-gray-600">25th:</span> <%= display_data(@data.l25) %></div>
            <div><span class="font-medium text-gray-600">50th:</span> <%= display_data(@data.l50) %></div>
            <div><span class="font-medium text-gray-600">75th:</span> <%= display_data(@data.l75) %></div>
          </div>
        </div>

        <div class="grid sm:grid-cols-4 gap-4 text-sm mb-4">
          <div class="font-semibold text-gray-800 col-span-full sm:col-span-1 mt-2 sm:mt-0">GPA</div>
          <div class="sm:col-span-3 grid grid-cols-3 gap-4 text-gray-800">
            <div><span class="font-medium text-gray-600">25th:</span> <%= display_data(@data.g25) %></div>
            <div><span class="font-medium text-gray-600">50th:</span> <%= display_data(@data.g50) %></div>
            <div><span class="font-medium text-gray-600">75th:</span> <%= display_data(@data.g75) %></div>
          </div>
        </div>
      </div>
      <div>
        <%= if has_gre_data?(@data, :v) do %>
          <div class="grid sm:grid-cols-4 gap-4 text-sm mb-4">
            <div class="font-semibold text-gray-800 col-span-full sm:col-span-1 mt-2 sm:mt-0">GRE Verbal</div>
            <div class="sm:col-span-3 grid grid-cols-3 gap-4 text-gray-800">
              <div><span class="font-medium text-gray-600">25th:</span> <%= display_data(@data.gre25v) %></div>
              <div><span class="font-medium text-gray-600">50th:</span> <%= display_data(@data.gre50v) %></div>
              <div><span class="font-medium text-gray-600">75th:</span> <%= display_data(@data.gre75v) %></div>
            </div>
          </div>
        <% end %>

        <%= if has_gre_data?(@data, :q) do %>
          <div class="grid sm:grid-cols-4 gap-4 text-sm mb-4">
            <div class="font-semibold text-gray-800 col-span-full sm:col-span-1 mt-2 sm:mt-0">GRE Quant</div>
            <div class="sm:col-span-3 grid grid-cols-3 gap-4 text-gray-800">
              <div><span class="font-medium text-gray-600">25th:</span> <%= display_data(@data.gre25q) %></div>
              <div><span class="font-medium text-gray-600">50th:</span> <%= display_data(@data.gre50q) %></div>
              <div><span class="font-medium text-gray-600">75th:</span> <%= display_data(@data.gre75q) %></div>
            </div>
          </div>
        <% end %>

        <%= if has_gre_data?(@data, :w) do %>
          <div class="grid sm:grid-cols-4 gap-4 text-sm mb-4">
            <div class="font-semibold text-gray-800 col-span-full sm:col-span-1 mt-2 sm:mt-0">GRE Writing</div>
            <div class="sm:col-span-3 grid grid-cols-3 gap-4 text-gray-800">
              <div><span class="font-medium text-gray-600">25th:</span> <%= display_data(@data.gre25w) %></div>
              <div><span class="font-medium text-gray-600">50th:</span> <%= display_data(@data.gre50w) %></div>
              <div><span class="font-medium text-gray-600">75th:</span> <%= display_data(@data.gre75w) %></div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp error(assigns) do
     ~H"""
     <p :if={Map.get(assigns, :if, true)} class="mt-1 text-sm text-red-600"><%= render_slot(@inner_block) %></p>
     """
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

  defp prepare_trend_chart_data(trend_data) do
    years = Enum.map(trend_data, &to_string(&1.first_year_class))
    lsat_values = Enum.map(trend_data, &(Map.get(&1, :l50) |> ensure_numeric_or_null()))
    gpa_values = Enum.map(trend_data, &(Map.get(&1, :g50) |> ensure_numeric_or_null()))

    valid_lsat = Enum.count(lsat_values, &(!is_nil(&1))) >= 2
    valid_gpa = Enum.count(gpa_values, &(!is_nil(&1))) >= 2

    if valid_lsat or valid_gpa do
      %{ labels: years,
         datasets: [
           %{ label: "Median LSAT", data: lsat_values, borderColor: "rgb(54, 162, 235)", backgroundColor: "rgba(54, 162, 235, 0.5)", tension: 0.1, yAxisID: "y" },
           %{ label: "Median GPA", data: Enum.map(gpa_values, &decimal_to_float_or_nil/1), borderColor: "rgb(255, 99, 132)", backgroundColor: "rgba(255, 99, 132, 0.5)", tension: 0.1, yAxisID: "y1" }
         ] }
    else nil end
  end

  defp prepare_rank_chart_data(trend_data) do
    years = Enum.map(trend_data, &to_string(&1.first_year_class))
    rank_values = Enum.map(trend_data, &(Map.get(&1, :rank) |> rank_to_numeric()))
    valid_ranks = Enum.count(rank_values, &(!is_nil(&1)))

    if valid_ranks >= 2 do
      %{ labels: years,
         datasets: [
           %{ label: "Rank", data: rank_values, borderColor: "rgb(75, 192, 192)", backgroundColor: "rgba(75, 192, 192, 0.5)", tension: 0.1, yAxisID: "yRank" }
         ] }
    else nil end
  end

  defp prepare_gre_chart_data(trend_data) do
    years = Enum.map(trend_data, &to_string(&1.first_year_class))
    gre_fields = [
      {:gre25v, "V25", "rgb(255, 159, 64)"}, {:gre50v, "V50", "rgb(255, 99, 132)"}, {:gre75v, "V75", "rgb(200, 70, 100)"},
      {:gre25q, "Q25", "rgb(153, 102, 255)"}, {:gre50q, "Q50", "rgb(75, 0, 130)"}, {:gre75q, "Q75", "rgb(50, 0, 100)"},
      {:gre25w, "W25", "rgb(201, 203, 207)"}, {:gre50w, "W50", "rgb(54, 162, 235)"}, {:gre75w, "W75", "rgb(0, 100, 200)"}
    ]
    datasets =
      Enum.map(gre_fields, fn {field_key, label, color} ->
        data_points = Enum.map(trend_data, &(Map.get(&1, field_key) |> ensure_numeric_or_null() |> decimal_to_float_or_nil()))
        y_axis = if String.starts_with?(label, "W"), do: "yGreW", else: "yGreVQ"
        %{ label: label, data: data_points, borderColor: color, backgroundColor: "#{String.replace(color, ")", ", 0.2)")}", tension: 0.1, yAxisID: y_axis, pointRadius: 3 }
      end)
    has_any_gre_data = Enum.any?(datasets, fn ds -> Enum.any?(ds.data, &(!is_nil(&1))) end)
    has_enough_points = Enum.any?(datasets, fn ds -> Enum.count(ds.data, &(!is_nil(&1))) >= 2 end)

    if has_any_gre_data && has_enough_points do
      %{ labels: years, datasets: datasets }
    else nil end
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
  rescue _ -> nil
  end
  defp rank_to_numeric(_), do: nil

end
