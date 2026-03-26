import { ref } from 'vue'

// Module-level singleton state
const connected = ref(false)
const callbacks = new Set()
let ws = null
let reconnectTimer = null

function connect() {
  if (ws && (ws.readyState === WebSocket.CONNECTING || ws.readyState === WebSocket.OPEN)) {
    return
  }

  const protocol = location.protocol === 'https:' ? 'wss:' : 'ws:'
  ws = new WebSocket(`${protocol}//${location.host}/ws`)

  ws.onopen = () => {
    connected.value = true
    if (reconnectTimer) {
      clearTimeout(reconnectTimer)
      reconnectTimer = null
    }
  }

  ws.onmessage = (event) => {
    if (event.data === 'refresh') {
      callbacks.forEach((fn) => fn())
    }
    // 'ping' messages are silently ignored
  }

  ws.onclose = () => {
    connected.value = false
    ws = null
    reconnectTimer = setTimeout(connect, 3000)
  }

  ws.onerror = () => {
    // onclose will fire after onerror — reconnect handled there
  }
}

// Initialize connection immediately when the module loads
if (typeof window !== 'undefined') {
  connect()
}

/**
 * Returns the shared WebSocket composable.
 * All callers share the same connection and `connected` ref.
 */
export function useWebSocket() {
  /**
   * Register a callback to be called on every 'refresh' WebSocket message.
   * Returns a cleanup function that unregisters the callback.
   */
  function onRefresh(fn) {
    callbacks.add(fn)
    return () => callbacks.delete(fn)
  }

  return { connected, onRefresh }
}
