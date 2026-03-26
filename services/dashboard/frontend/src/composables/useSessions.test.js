import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

const mockSessions = [
  { session_id: 'mec-node-001', tool: 'node', exit_code: 0, ai_status: 'done', timestamp: '2026-01-01T00:00:00Z' },
  { session_id: 'mec-npm-002', tool: 'npm', exit_code: 1, ai_status: 'pending', timestamp: '2026-01-01T00:01:00Z' },
  { session_id: 'mec-node-003', tool: 'node', exit_code: 0, ai_status: 'none', timestamp: '2026-01-01T00:02:00Z' },
  { session_id: 'mec-terraform-004', tool: 'terraform', exit_code: 1, ai_status: 'done', timestamp: '2026-01-01T00:03:00Z' },
]

beforeEach(() => {
  vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
    ok: true,
    json: () => Promise.resolve(mockSessions),
  }))
})

afterEach(() => {
  vi.restoreAllMocks()
  vi.unstubAllGlobals()
  vi.resetModules()
})

describe('useSessions — makeFiltered', () => {
  it('returns all sessions when no filters applied', async () => {
    const { useSessions } = await import('./useSessions.js')
    const { sessions, fetchSessions, makeFiltered } = useSessions()
    await fetchSessions()

    const filtered = makeFiltered({ tools: [], aiStatus: 'all', exitCode: 'all', search: '' })
    expect(filtered.value).toHaveLength(4)
  })

  it('filters by tool', async () => {
    const { useSessions } = await import('./useSessions.js')
    const { fetchSessions, makeFiltered } = useSessions()
    await fetchSessions()

    const filtered = makeFiltered({ tools: ['node'], aiStatus: 'all', exitCode: 'all', search: '' })
    expect(filtered.value).toHaveLength(2)
    expect(filtered.value.every((s) => s.tool === 'node')).toBe(true)
  })

  it('filters by AI status', async () => {
    const { useSessions } = await import('./useSessions.js')
    const { fetchSessions, makeFiltered } = useSessions()
    await fetchSessions()

    const filtered = makeFiltered({ tools: [], aiStatus: 'done', exitCode: 'all', search: '' })
    expect(filtered.value).toHaveLength(2)
    expect(filtered.value.every((s) => s.ai_status === 'done')).toBe(true)
  })

  it('filters by exit code success', async () => {
    const { useSessions } = await import('./useSessions.js')
    const { fetchSessions, makeFiltered } = useSessions()
    await fetchSessions()

    const filtered = makeFiltered({ tools: [], aiStatus: 'all', exitCode: 'success', search: '' })
    expect(filtered.value).toHaveLength(2)
    expect(filtered.value.every((s) => s.exit_code === 0)).toBe(true)
  })

  it('filters by exit code failure', async () => {
    const { useSessions } = await import('./useSessions.js')
    const { fetchSessions, makeFiltered } = useSessions()
    await fetchSessions()

    const filtered = makeFiltered({ tools: [], aiStatus: 'all', exitCode: 'failure', search: '' })
    expect(filtered.value).toHaveLength(2)
    expect(filtered.value.every((s) => s.exit_code !== 0)).toBe(true)
  })

  it('filters by search text on session_id', async () => {
    const { useSessions } = await import('./useSessions.js')
    const { fetchSessions, makeFiltered } = useSessions()
    await fetchSessions()

    const filtered = makeFiltered({ tools: [], aiStatus: 'all', exitCode: 'all', search: 'terraform' })
    expect(filtered.value).toHaveLength(1)
    expect(filtered.value[0].session_id).toBe('mec-terraform-004')
  })

  it('combines multiple filters', async () => {
    const { useSessions } = await import('./useSessions.js')
    const { fetchSessions, makeFiltered } = useSessions()
    await fetchSessions()

    const filtered = makeFiltered({ tools: ['node'], aiStatus: 'done', exitCode: 'success', search: '' })
    expect(filtered.value).toHaveLength(1)
    expect(filtered.value[0].session_id).toBe('mec-node-001')
  })
})
