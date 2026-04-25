// LiveView hook that renders a supply-chain graph with vis-network.
// vis-network is loaded from a CDN at runtime to avoid bundling weight.

const VIS_URL = "https://unpkg.com/vis-network@9.1.9/standalone/umd/vis-network.min.js"

let visLoading = null
function loadVis() {
  if (window.vis && window.vis.Network) return Promise.resolve(window.vis)
  if (visLoading) return visLoading
  visLoading = new Promise((resolve, reject) => {
    const s = document.createElement("script")
    s.src = VIS_URL
    s.onload = () => resolve(window.vis)
    s.onerror = reject
    document.head.appendChild(s)
  })
  return visLoading
}

export default {
  async mounted() {
    const data = JSON.parse(this.el.dataset.graph)
    const vis = await loadVis()

    const colors = {
      us: "#22c55e",
      supplier: "#3b82f6",
      customer: "#f97316",
      both: "#a855f7",
    }

    const nodes = new vis.DataSet(
      data.nodes.map(n => ({
        ...n,
        color: { background: colors[n.group] || "#9ca3af", border: "#1f2937" },
        shape: n.group === "us" ? "star" : "dot",
        size: n.group === "us" ? 28 : 20,
        font: { color: "#f1f5f9" },
      }))
    )

    const edges = new vis.DataSet(data.edges)

    const network = new vis.Network(this.el, { nodes, edges }, {
      physics: { stabilization: { iterations: 200 } },
      interaction: { hover: true },
      edges: { arrows: "to", color: { color: "#64748b" }, font: { color: "#cbd5f5", strokeWidth: 0 } },
    })

    network.on("selectNode", (params) => {
      if (params.nodes && params.nodes[0]) {
        this.pushEvent("select_vendor", { id: String(params.nodes[0]) })
      }
    })

    this.network = network
  },

  destroyed() {
    if (this.network) this.network.destroy()
  },
}
