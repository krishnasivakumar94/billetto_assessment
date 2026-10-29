const publishableKey = document.querySelector('meta[name="clerk-publishable-key"]')?.content

function showStatus(message) {
  const status = document.getElementById("auth-status")
  if (!status) return
  status.textContent = message
  status.hidden = false
  window.setTimeout(() => { status.hidden = true }, 4500)
}

function frontendApiFromKey(key) {
  const encoded = key.match(/^pk_(?:test|live)_(.+)$/)?.[1]?.replace(/\$$/, "")
  if (!encoded) throw new Error("Invalid Clerk publishable key")
  const base64 = encoded.replace(/-/g, "+").replace(/_/g, "/")
  const frontendApi = atob(base64 + "=".repeat((4 - base64.length % 4) % 4)).replace(/\$$/, "")
  if (!frontendApi) throw new Error("Invalid Clerk publishable key")
  return frontendApi
}

function loadScript(src, attributes = {}) {
  return new Promise((resolve, reject) => {
    const script = document.createElement("script")
    script.src = src
    script.async = true
    script.crossOrigin = "anonymous"
    Object.entries(attributes).forEach(([name, value]) => script.setAttribute(name, value))
    script.onload = resolve
    script.onerror = () => reject(new Error("Unable to load Clerk. Check your publishable key and network."))
    document.head.appendChild(script)
  })
}

function updateAuthUi() {
  const signedIn = Boolean(window.Clerk?.isSignedIn)
  const signInButton = document.getElementById("clerk-sign-in")
  const userButton = document.getElementById("clerk-user-button")

  if (signInButton) signInButton.hidden = signedIn
  if (userButton) {
    userButton.hidden = !signedIn
    if (signedIn && !userButton.dataset.mounted) {
      window.Clerk.mountUserButton(userButton)
      userButton.dataset.mounted = "true"
    }
  }

  document.querySelectorAll(".vote-hint").forEach((hint) => {
    hint.hidden = signedIn
  })
}

async function initializeClerk() {
  const signInButton = document.getElementById("clerk-sign-in")
  if (!publishableKey) {
    signInButton?.addEventListener("click", () => showStatus("Add CLERK_PUBLISHABLE_KEY to enable Clerk sign-in."), { once: true })
    return
  }
  if (window.__eventAtlasClerkInitialized) return

  try {
    const frontendApi = frontendApiFromKey(publishableKey)
    const baseUrl = `https://${frontendApi}/npm`
    await Promise.all([
      loadScript(`${baseUrl}/@clerk/ui@1/dist/ui.browser.js`),
      loadScript(`${baseUrl}/@clerk/clerk-js@6/dist/clerk.browser.js`, { "data-clerk-publishable-key": publishableKey })
    ])

    await window.Clerk.load({ ui: { ClerkUI: window.__internal_ClerkUICtor } })
    updateAuthUi()
    window.Clerk.addListener(updateAuthUi)
    signInButton?.addEventListener("click", () => window.Clerk.openSignIn())

    document.querySelectorAll("form.event-vote-form").forEach((form) => {
      form.addEventListener("submit", async (event) => {
        event.preventDefault()
        if (!window.Clerk.isSignedIn) {
          window.Clerk.openSignIn()
          return
        }

        try {
          const token = await window.Clerk.session.getToken()
          const response = await fetch(form.action, {
            method: "POST",
            headers: {
              "Accept": "application/json",
              "Authorization": `Bearer ${token}`,
              "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
              "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content || ""
            },
            body: new URLSearchParams(new FormData(form))
          })

          if (response.status === 401) {
            window.Clerk.openSignIn()
            return
          }
          if (!response.ok) throw new Error("The vote could not be saved. Please try again.")
          window.location.reload()
        } catch (error) {
          showStatus(error.message)
        }
      })
    })
    window.__eventAtlasClerkInitialized = true
  } catch (error) {
    showStatus(error.message)
    const signInButton = document.getElementById("clerk-sign-in")
    signInButton?.addEventListener("click", () => showStatus("Add CLERK_PUBLISHABLE_KEY to enable Clerk sign-in."))
  }
}

document.addEventListener("turbo:load", initializeClerk)
