import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import Chart from "chart.js/auto";

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

let Hooks = {};

// --- Helper to Destroy Chart Safely ---
function destroyChart(hookInstance) {
  if (hookInstance.chart) {
    hookInstance.chart.destroy();
    hookInstance.chart = null;
  }
}

// --- Define the LSAT/GPA TrendChart Hook ---
Hooks.TrendChart = {
  chart: null,
  mounted() {
    const chartId = "trendChart";
    console.log("TrendChart Hook Mounted! ID:", chartId);
    this.el = document.getElementById(chartId);
    if (!this.el) {
      console.error("Canvas element not found:", chartId);
      return;
    }

    this.handleEvent("update_trend_chart", (payload) => {
      console.log("Received update_trend_chart event for ID:", chartId);
      const dataString = payload.data;
      if (dataString) {
        this.renderChart(dataString);
      } else {
        destroyChart(this);
      }
    });
  },
  destroyed() {
    destroyChart(this);
  },
  renderChart(chartDataString) {
    destroyChart(this);
    if (!chartDataString) {
      return;
    }
    try {
      const chartData = JSON.parse(chartDataString);
      if (!this.el || !this.el.getContext) {
        console.error("TrendChart: Invalid canvas.");
        return;
      }
      const ctx = this.el.getContext("2d");
      if (!ctx) {
        console.error("TrendChart: Failed context.");
        return;
      }

      this.chart = new Chart(ctx, {
        type: "line",
        data: chartData,
        options: {
          responsive: true,
          maintainAspectRatio: false,
          animation: false,
          interaction: { mode: "index", intersect: false },
          plugins: { title: { display: false }, legend: { position: "top" } },
          scales: {
            y: {
              type: "linear",
              display: true,
              position: "left",
              title: { display: true, text: "Median LSAT" },
              suggestedMin: 120,
              suggestedMax: 180,
            },
            y1: {
              type: "linear",
              display: true,
              position: "right",
              title: { display: true, text: "Median GPA" },
              min: 2.0,
              max: 4.33,
              grid: { drawOnChartArea: false },
            },
            x: { title: { display: true, text: "Year" } },
          },
        },
      });
    } catch (e) {
      console.error("TrendChart Error:", e, chartDataString);
      destroyChart(this);
    }
  },
};

// --- Define the RankChart Hook ---
Hooks.RankChart = {
  chart: null,
  mounted() {
    const chartId = "rankChart";

    this.el = document.getElementById(chartId);
    if (!this.el) {
      console.error("Canvas element not found:", chartId);
      return;
    }

    this.handleEvent("update_rank_chart", (payload) => {
      const dataString = payload.data;
      if (dataString) {
        this.renderChart(dataString);
      } else {
        destroyChart(this);
      }
    });
  },
  destroyed() {
    destroyChart(this);
  },
  renderChart(chartDataString) {
    destroyChart(this);
    if (!chartDataString) {
      return;
    }
    try {
      const chartData = JSON.parse(chartDataString);
      if (!this.el || !this.el.getContext) {
        console.error("RankChart: Invalid canvas.");
        return;
      }
      const ctx = this.el.getContext("2d");
      if (!ctx) {
        console.error("RankChart: Failed context.");
        return;
      }

      this.chart = new Chart(ctx, {
        type: "line",
        data: chartData,
        options: {
          responsive: true,
          maintainAspectRatio: false,
          animation: false,
          interaction: { mode: "index", intersect: false },
          plugins: { title: { display: false }, legend: { display: false } },
          scales: {
            yRank: {
              type: "linear",
              display: true,
              position: "left",
              reverse: true,
              title: { display: true, text: "Rank" },
              min: 1,
              suggestedMax: 147,
            },
            x: { title: { display: true, text: "Year" } },
          },
        },
      });
    } catch (e) {
      console.error("RankChart Error:", e, chartDataString);
      destroyChart(this);
    }
  },
};

// --- Define the GreChart Hook ---
Hooks.GreChart = {
  chart: null,
  mounted() {
    const chartId = "greChart";
    this.el = document.getElementById(chartId);
    if (!this.el) {
      console.error("Canvas element not found:", chartId);
      return;
    }

    this.handleEvent("update_gre_chart", (payload) => {
      const dataString = payload.data;
      if (dataString) {
        this.renderChart(dataString);
      } else {
        destroyChart(this);
      }
    });
  },
  destroyed() {
    destroyChart(this);
  },
  renderChart(chartDataString) {
    destroyChart(this);
    if (!chartDataString) {
      return;
    }
    try {
      const chartData = JSON.parse(chartDataString);
      if (!this.el || !this.el.getContext) {
        console.error("GreChart: Invalid canvas.");
        return;
      }
      const ctx = this.el.getContext("2d");
      if (!ctx) {
        console.error("GreChart: Failed context.");
        return;
      }
      this.chart = new Chart(ctx, {
        type: "line",
        data: chartData,
        options: {
          responsive: true,
          maintainAspectRatio: false,
          animation: false,
          interaction: { mode: "index", intersect: false },
          plugins: {
            title: { display: false },
            legend: {
              position: "top",
              labels: { boxWidth: 10, font: { size: 10 } },
            },
          },
          scales: {
            yGreVQ: {
              type: "linear",
              display: true,
              position: "left",
              title: { display: true, text: "GRE V/Q Score" },
              suggestedMin: 140,
              suggestedMax: 175,
            },
            yGreW: {
              type: "linear",
              display: true,
              position: "right",
              title: { display: true, text: "GRE W Score" },
              min: 0,
              max: 6,
              ticks: { stepSize: 0.5 },
              grid: { drawOnChartArea: false },
            },
            x: { title: { display: true, text: "Year" } },
          },
        },
      });
    } catch (e) {
      console.error("GreChart Error:", e, chartDataString);
      destroyChart(this);
    }
  },
};

// --- Initialize LiveSocket ---
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

// --- Topbar and Connection ---
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());
liveSocket.connect();
window.liveSocket = liveSocket;

// --- Live Reload ---
if (process.env.NODE_ENV === "development") {
  window.addEventListener(
    "phx:live_reload:attached",
    ({ detail: reloader }) => {
      reloader.enableServerLogs();
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
