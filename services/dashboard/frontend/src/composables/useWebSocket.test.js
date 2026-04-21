import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

// We need to reset the module between tests since it's a singleton
// Use a fresh import for each test group

describe('useWebSocket', () => {
  let MockWebSocket
  let instances

  beforeEach(() => {
    instances = []
    MockWebSocket = vi.fn().mockImplementation(function (url) {
      this.url = url
      this.readyState = 0 // CONNECTING
      this.send = vi.fn()
      this.close = vi.fn()
      this.onopen = null
      this.onmessage = null
      this.onclose = null
      this.onerror = null
      instances.push(this)
    })
    MockWebSocket.CONNECTING = 0
    MockWebSocket.OPEN = 1
    MockWebSocket.CLOSING = 2
    MockWebSocket.CLOSED = 3
    vi.stubGlobal('WebSocket', MockWebSocket)
  })

  afterEach(() => {
    vi.restoreAllMocks()
    vi.unstubAllGlobals()
    vi.resetModules()
  })

  it('calls registered refresh callbacks on "refresh" message', async () => {
    const { useWebSocket } = await import('./useWebSocket.js')
    const { onRefresh } = useWebSocket()

    const callback = vi.fn()
    onRefresh(callback)

    // Simulate WebSocket "refresh" message
    const ws = instances[instances.length - 1]
    ws.onmessage?.({ data: 'refresh' })

    expect(callback).toHaveBeenCalledTimes(1)
  })

  it('ignores "ping" messages', async () => {
    const { useWebSocket } = await import('./useWebSocket.js')
    const { onRefresh } = useWebSocket()

    const callback = vi.fn()
    onRefresh(callback)

    const ws = instances[instances.length - 1]
    ws.onmessage?.({ data: 'ping' })

    expect(callback).not.toHaveBeenCalled()
  })

  it('returns same instance on multiple calls (singleton)', async () => {
    const { useWebSocket } = await import('./useWebSocket.js')
    const a = useWebSocket()
    const b = useWebSocket()
    expect(a.connected).toBe(b.connected)
  })

  it('cleanup function removes callback', async () => {
    const { useWebSocket } = await import('./useWebSocket.js')
    const { onRefresh } = useWebSocket()

    const callback = vi.fn()
    const cleanup = onRefresh(callback)
    cleanup()

    const ws = instances[instances.length - 1]
    ws.onmessage?.({ data: 'refresh' })

    expect(callback).not.toHaveBeenCalled()
  })

  it('updates connected ref on open/close', async () => {
    const { useWebSocket } = await import('./useWebSocket.js')
    const { connected } = useWebSocket()

    const ws = instances[instances.length - 1]
    ws.onopen?.()
    expect(connected.value).toBe(true)

    ws.onclose?.()
    expect(connected.value).toBe(false)
  })
})
