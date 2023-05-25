// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
// import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "topbar";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

import tippy from "tippy.js";

const TippyHook = {
  mounted() {
    const templateId = this.el.dataset.template;
    const template = document.getElementById(templateId);

    if (template) {
      const content = template.content.cloneNode(true);

      if (content) {
        tippy(this.el, { content, allowHTML: true, interactive: true });
      }
    }
  },
};

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: { TippyHook },
  params: { _csrf_token: csrfToken },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (info) => topbar.show(200));
window.addEventListener("phx:page-loading-stop", (info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
