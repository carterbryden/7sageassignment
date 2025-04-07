defmodule SevensageassignmentWeb.FirstYearRankingsLive do
  use SevensageassignmentWeb, :live_view
  alias Sevensageassignment.FirstYearRankings # Your actual context module

  @impl true
  def mount(_params, _session, socket) do

    # Opting for storing a bit more data in assigns for simplicity.
    # If we're expecting thousands of concurrent users or the data set
    # is expected to get really large, we might want to use liveview
    # streams instead to take the memory load off of the server.
    socket =
      assign(socket,
        query: "",
        search_results: [],             # List of school name strings
        selected_school_name: nil,      # Store the name of the selected school
        selected_ranking_data: nil,     # Holds the struct for the LATEST year of the selected school
        school_trend_data: [],          # Holds list of structs for the selected school's history
        chart_data_json: nil,           # Holds JSON string for the Chart.js hook
        show_chart: false,
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
     chart_data = prepare_chart_data(trend_data)
     chart_data_json = if chart_data, do: Jason.encode!(chart_data), else: nil # Encode it

     socket = assign(socket,
        query: "",
        search_results: [],
        selected_school_name: school_name,
        selected_ranking_data: latest_data,
        school_trend_data: trend_data,
        show_chart: !is_nil(chart_data_json),
        search_active: false
      )

     # Push event to JS hook with the chart data (or nil)
     {:noreply, push_event(socket, "update_chart", %{data: chart_data_json})}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-6 bg-gray-50 rounded-lg shadow-md space-y-6">
      <h1 class="text-2xl font-bold text-center text-gray-800 mb-4">Law School First Year Class Data</h1>

      <% # Search Section %>
      <div class="relative mb-6">
        <label for="school_search" class="block text-sm font-medium text-gray-700 mb-1">Search for School</label>
        <.input
          id="school_search"
          type="text"
          name="query"
          value={@query}
          phx-keyup="search_school"
          phx-debounce="300"
          autocomplete="off"
          placeholder="e.g. Harvard"
          class="w-full"
        />

        <.error :if={@search_active && @search_results == [] && is_nil(@selected_school_name)}>
          No matching schools found for "<%= @query %>".
        </.error>

        <% # Autocomplete Dropdown - Iterates over school names, triggers select_school %>
        <div :if={@search_results != []} class="absolute z-10 mt-1 w-full bg-white shadow-lg max-h-60 rounded-md py-1 text-base ring-1 ring-black ring-opacity-5 overflow-auto focus:outline-none sm:text-sm">
          <ul>
            <li :for={school_name <- @search_results}
                class="text-gray-900 cursor-pointer select-none relative py-2 pl-3 pr-9 hover:bg-sky-600 hover:text-white"
                phx-click="select_school"
                phx-value-name={school_name}
                phx-key={school_name}>
              <%= school_name %>
            </li>
          </ul>
        </div>
      </div>

      <div :if={@selected_ranking_data} class="mt-6 space-y-6 p-4 border border-gray-200 rounded-lg bg-white">
        <div class="flex justify-between items-center">
          <h2 class="text-xl font-semibold text-sky-700">
            <% # Display school name and the latest year found %>
            <%= @selected_ranking_data.school %> - <%= @selected_ranking_data.first_year_class %> Data (Latest Available)
          </h2>
        </div>

        <p class="text-gray-700 italic">
          For the <%= @selected_ranking_data.first_year_class %> entering class at <%= @selected_ranking_data.school %>,
          the median LSAT score was <%= display_data(@selected_ranking_data.l50) %>
          and the median GPA was <%= display_data(@selected_ranking_data.g50) %>.
        </p>

        <div class="overflow-x-auto">
           <.data_table data={@selected_ranking_data} />
        </div>

        <div class="mt-8">
           <h3 class="text-lg font-medium text-gray-800 mb-2">Median LSAT & GPA Trends (<%= @selected_ranking_data.school %>)</h3>
           <div :if={@show_chart} class="bg-gray-100 p-4 rounded relative h-72 md:h-96">
              <canvas
                id={"trendChart"}
                phx-hook="TrendChart"
                phx-update="ignore">
                <% # Chart.js will render here %>
              </canvas>
           </div>
           <% # Show message if chart JSON couldn't be generated (not enough trend data) %>
           <p :if={!@show_chart} class="text-gray-500 text-sm mt-2">
             Not enough historical data to display trends for this school.
           </p>
        </div>
      </div>
       <% # Message if school selected but somehow no data found %>
       <div :if={@selected_school_name && is_nil(@selected_ranking_data)} class="text-center text-gray-500 mt-6">
          No ranking data found for <%= @selected_school_name %>.
        </div>

      <% # Placeholder message when nothing is selected %>
      <div :if={is_nil(@selected_school_name) && !@search_active && @query == ""} class="text-center text-gray-500 mt-6">
        Please search for and select a school to view its data.
      </div>

    </div>
    """
  end

  #Helper Component for the Data Table
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

  #Error component
  defp error(assigns) do
    ~H"""
    <p :if={Map.get(assigns, :if, true)} class="mt-1 text-sm text-red-600"><%= render_slot(@inner_block) %></p>
    """
  end

  #Helper to display data or "N/A"
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

  #Helper to check if any GRE data exists
  defp has_gre_data?(data, category) when category in [:v, :q, :w] do
    prefix = "gre"
    suffixes = ["25", "50", "75"]
    keys = Enum.map(suffixes, &String.to_atom("#{prefix}#{&1}#{category}"))
    Enum.any?(keys, fn key ->
      val = Map.get(data, key)
      !(is_nil(val) || val == "")
    end)
  end

  #Prepare data for Chart.js
  defp prepare_chart_data(trend_data) do
    # Data should already be sorted by year from get_rankings_by_school
    years = Enum.map(trend_data, &to_string(&1.first_year_class))
    lsat_values = Enum.map(trend_data, &(Map.get(&1, :l50) |> ensure_numeric_or_null()))
    gpa_values = Enum.map(trend_data, &(Map.get(&1, :g50) |> ensure_numeric_or_null()))

    valid_lsat_points = Enum.count(lsat_values, &(!is_nil(&1)))
    valid_gpa_points = Enum.count(gpa_values, &(!is_nil(&1)))

    if valid_lsat_points >= 2 or valid_gpa_points >= 2 do
      %{
        labels: years,
        datasets: [
          %{
            label: "Median LSAT",
            data: lsat_values,
            borderColor: "rgb(54, 162, 235)", # Blue
            backgroundColor: "rgba(54, 162, 235, 0.5)",
            tension: 0.1,
            yAxisID: "y" # Primary axis
          },
          %{
            label: "Median GPA",
            data: Enum.map(gpa_values, &decimal_to_float_or_nil/1), # Convert Decimal
            borderColor: "rgb(255, 99, 132)", # Red
            backgroundColor: "rgba(255, 99, 132, 0.5)",
            tension: 0.1,
            yAxisID: "y1" # Secondary axis
          }
        ]
      }
    else
      nil
    end
  end

  defp ensure_numeric_or_null(val) when is_integer(val), do: val
  defp ensure_numeric_or_null(%Decimal{} = val), do: val
  defp ensure_numeric_or_null(_), do: nil

  defp decimal_to_float_or_nil(%Decimal{} = dec), do: Decimal.to_float(dec)
  defp decimal_to_float_or_nil(_), do: nil

end
