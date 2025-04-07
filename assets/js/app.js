// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import Chart from "chart.js/auto"; // fine for a demo, probably be more selective to save bundle size in production

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

let Hooks = {};

// Define the TrendChart Hook
Hooks.TrendChart = {
  chart: null, // To hold the chart instance

  mounted() {
    console.log("mounted chart");
    this.handleEvent("update_chart", (payload) => {
      console.log("Received update_chart event", "Payload:", payload);
      const dataString = payload.data; // data can be null/undefined to clear chart
      if (dataString) {
        this.renderChart(dataString);
      } else {
        this.destroyChart(); // Clear the chart if data is null/undefined
      }
    });

    this.renderChart();
  },

  updated() {
    console.log("Chart html updated");
    this.renderChart();
  },

  destroyChart() {
    if (this.chart) {
      this.chart.destroy();
      this.chart = null;
      console.log("Chart instance destroyed. ID:", this.el.id);
    }
  },

  destroyed() {
    if (this.chart) {
      this.chart.destroy();
      this.chart = null;
      console.log("Chart destroyed");
    }
  },

  renderChart(chartDataString) {
    this.destroyChart(); // Always destroy previous instance before rendering

    if (!chartDataString) {
      console.log("renderChart called with no data string. ID:", this.el.id);
      return; // Don't render if no data
    }

    try {
      const chartData = JSON.parse(chartDataString);
      if (!this.el || typeof this.el.getContext !== "function") {
        console.error(
          "Canvas element not available or invalid. ID:",
          this.el.id
        );
        return;
      }
      const ctx = this.el.getContext("2d");
      if (!ctx) {
        console.error("Failed to get 2D context. ID:", this.el.id);
        return;
      }

      console.log("Rendering chart - ID:", this.el.id);

      this.chart = new Chart(ctx, {
        type: "line",
        data: chartData, // Use parsed data directly {labels: [...], datasets: [...]}
        options: {
          responsive: true,
          maintainAspectRatio: false, // Allows chart to fill container height
          animation: false,
          interaction: {
            mode: "index", // Show tooltips for all datasets at that index
            intersect: false,
          },
          stacked: false,
          plugins: {
            title: {
              display: false, // Title is already in H3 above canvas
            },
            legend: {
              position: "top",
            },
          },
          scales: {
            y: {
              // Primary Y-axis (LSAT)
              type: "linear",
              display: true,
              position: "left",
              title: {
                display: true,
                text: "Median LSAT",
              },
              // Suggest min/max based on typical LSAT range
              suggestedMin: 120,
              suggestedMax: 180,
            },
            y1: {
              // Secondary Y-axis (GPA)
              type: "linear",
              display: true,
              position: "right",
              title: {
                display: true,
                text: "Median GPA",
              },
              // Suggest min/max based on typical GPA range
              suggestedMin: 2.0,
              sugesstedMax: 4.5,
              // grid line settings
              grid: {
                drawOnChartArea: false, // only want the grid lines for one axis to show up
              },
            },
            x: {
              // X-axis (Year)
              title: {
                display: true,
                text: "Year",
              },
            },
          },
        },
      });
    } catch (e) {
      console.error(
        "Failed to parse/render chart - ID:",
        this.el.id,
        "Error:",
        e,
        "Data:",
        chartDataString
      );
      this.destroyChart(); // Clean up on error
    }
  },
};

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener(
    "phx:live_reload:attached",
    ({ detail: reloader }) => {
      // Enable server log streaming to client.
      // Disable with reloader.disableServerLogs()
      reloader.enableServerLogs();

      // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
      //
      //   * click with "c" key pressed to open at caller location
      //   * click with "d" key pressed to open at function component definition location
      let keyDown;
      window.addEventListener("keydown", (e) => (keyDown = e.key));
      window.addEventListener("keyup", (e) => (keyDown = null));
      window.addEventListener(
        "click",
        (e) => {
          if (keyDown === "c") {
            e.preventDefault();
            e.stopImmediatePropagation();
            reloader.openEditorAtCaller(e.target);
          } else if (keyDown === "d") {
            e.preventDefault();
            e.stopImmediatePropagation();
            reloader.openEditorAtDef(e.target);
          }
        },
        true
      );

      window.liveReloader = reloader;
    }
  );
}
