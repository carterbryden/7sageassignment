# lib/sevensageassignment_web/live/first_year_rankings_live.ex
defmodule SevensageassignmentWeb.FirstYearRankingsLive do
  use SevensageassignmentWeb, :live_view
  alias Sevensageassignment.FirstYearRankings

  @impl true
  def mount(_params, _session, socket) do
    # Initial state: query and selection are empty, no search results yet.
    socket =
      assign(socket,
        query: "",
        search_results: [],    # Will hold list of FirstYearRanking structs
        selected_school: nil,
        selected_year: nil,
        search_active: false
      )
    {:ok, socket}
  end

  @impl true
  def handle_event("search_school", %{"value" => query}, socket) do
    trimmed_query = String.trim(query)
    search_active = trimmed_query != ""

    # Fetch full FirstYearRanking structs based on school name search
    search_results = FirstYearRankings.search_schools(trimmed_query)

    socket =
      assign(socket,
        query: query,
        search_results: search_results,
        search_active: search_active
      )
    {:noreply, socket}
  end

  # Handles selection of a specific "School - Year" combination
  @impl true
  def handle_event("select_combination", %{"school" => school_name, "year" => year_str}, socket) do
     year = String.to_integer(year_str)

     socket =
      assign(socket,
        query: "",
        search_results: [],      # Clear dropdown
        selected_school: school_name,
        selected_year: year,
        search_active: false
      )
    {:noreply, socket}
  end

  @impl true
  def handle_event("clear_selection", _, socket) do
    # Reset to initial state
    socket =
      assign(socket,
        selected_school: nil,
        selected_year: nil
      )
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto p-6 bg-gray-50 rounded-lg shadow-md space-y-4">
      <h2 class="text-xl font-semibold text-gray-800">Select School and Year</h2>

      <div class="relative">
        <label for="school_search" class="text-sm font-medium text-gray-700">Search for School</label>
        <.input
          id="school_search"
          type="text"
          name="query"
          value={@query}
          phx-keyup="search_school"
          phx-debounce="300"
          autocomplete="off"
          placeholder={"e.g. Yale"}
        />

        <.error :if={@search_active && @search_results == [] && is_nil(@selected_school)}>
          No matching school/year found for "<%= @query %>".
        </.error>

        <% # Autocomplete Dropdown: Shows "School - Year" %>
        <div :if={@search_results != []} class="absolute z-10 mt-1 w-full bg-white shadow-lg max-h-60 rounded-md py-1 text-base ring-1 ring-black ring-opacity-5 overflow-auto focus:outline-none sm:text-sm">
          <ul>
            <% # Iterate through the FirstYearRanking structs %>
            <li :for={ranking <- @search_results}
                class="text-gray-900 cursor-pointer select-none relative py-2 pl-3 pr-9 hover:bg-indigo-600 hover:text-white"
                phx-click="select_combination"
                phx-value-school={ranking.school}
                phx-value-year={ranking.first_year_class}
                phx-key={"#{ranking.school}-#{ranking.first_year_class}"}>
              <% # Display School - Year %>
              <%= ranking.school %> - <%= ranking.first_year_class %>
            </li>
          </ul>
        </div>
      </div>

      <% # Selected State Indicator %>
      <div :if={@selected_school && @selected_year} class="p-3 bg-indigo-100 border border-indigo-200 rounded-md flex justify-between items-center">
        <span class="text-gray-800 font-medium">
          Selected: <strong class="text-indigo-700"><%= @selected_school %> - <%= @selected_year %></strong>
        </span>
        <button phx-click="clear_selection" title="Clear selection" class="text-sm text-indigo-600 hover:text-indigo-800 font-medium px-2 py-1 rounded hover:bg-indigo-200 transition-colors duration-150">
          x Clear
        </button>
      </div>

      <% # Final Confirmation Message (optional) %>
      <div :if={@selected_school && @selected_year} class="mt-4 p-3 bg-green-100 border border-green-200 rounded-md">
        <p class="text-sm text-green-800">
          You selected: <strong><%= @selected_school %></strong> - Year: <strong><%= @selected_year %></strong>
        </p>
      </div>
    </div>
    """
  end

  defp error(assigns) do
     ~H"""
     <p :if={Map.get(assigns, :if, true)} class="mt-1 text-sm text-red-600"><%= render_slot(@inner_block) %></p>
     """
   end
end
