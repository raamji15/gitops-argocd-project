"use strict";

const byId = (id) => document.getElementById(id);

async function showRelease() {
  try {
    const response = await fetch("/version.json", { cache: "no-store" });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const release = await response.json();
    byId("version-badge").textContent = release.version;
    byId("release-version").textContent = release.version;
    byId("release-id").textContent = release.releaseId;
    byId("release-date").textContent = release.releaseDate;
    byId("release-title").textContent = release.releaseTitle;
    byId("release-summary").textContent = release.releaseNotes;
    byId("footer-release").textContent = `${release.version} · ${release.releaseId}`;
    const history = byId("release-history");
    history.replaceChildren(...release.history.map((item) => {
      const entry = document.createElement("li");
      const version = document.createElement("strong");
      version.textContent = item.version;
      entry.append(version, document.createTextNode(` — ${item.description}`));
      return entry;
    }));
  } catch (error) {
    byId("version-badge").textContent = "Release unavailable";
    byId("release-version").textContent = "Unavailable";
    byId("release-id").textContent = "Check version.json";
    byId("release-date").textContent = "—";
    byId("release-title").textContent = "Could not load release data";
    byId("release-summary").textContent = "The dashboard is available, but version.json could not be fetched.";
    byId("footer-release").textContent = "Release metadata unavailable";
    console.error("Could not load release metadata:", error);
  }
}

showRelease();
