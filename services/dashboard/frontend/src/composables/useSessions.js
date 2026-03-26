import { ref, computed } from 'vue'

const sessions = ref([])
const totalSessions = ref(0)
const loading = ref(false)
const error = ref(null)

/**
 * Fetch sessions from the API.
 * @param {object} params - Query parameters
 * @param {number} [params.limit=50] - Max sessions to fetch
 */
async function fetchSessions({ limit = 50 } = {}) {
  loading.value = true
  error.value = null
  try {
    const res = await fetch(`/api/sessions?limit=${limit}`)
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    const data = await res.json()
    sessions.value = data.sessions ?? data
    totalSessions.value = data.total ?? sessions.value.length
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

/**
 * Returns the sessions composable with client-side filtering.
 * Filters are applied reactively — change them and filteredSessions updates.
 */
export function useSessions() {
  /**
   * Build a filtered + searched view of sessions.
   * @param {object} filters
   * @param {string[]} [filters.tools] - Tool names to include (empty = all)
   * @param {string} [filters.aiStatus] - 'all'|'done'|'pending'|'none'
   * @param {string} [filters.exitCode] - 'all'|'success'|'failure'
   * @param {string} [filters.search] - Text search across session_id, command, and cwd
   */
  function makeFiltered(filters) {
    return computed(() => {
      let result = sessions.value

      const { tools = [], aiStatus = 'all', exitCode = 'all', search = '' } = filters

      if (tools.length > 0) {
        result = result.filter((s) => tools.includes(s.tool))
      }

      if (aiStatus !== 'all') {
        result = result.filter((s) => s.ai_status === aiStatus)
      }

      if (exitCode === 'success') {
        result = result.filter((s) => s.exit_code === 0)
      } else if (exitCode === 'failure') {
        result = result.filter((s) => s.exit_code !== 0)
      }

      if (search.trim()) {
        const q = search.trim().toLowerCase()
        result = result.filter((s) =>
          s.session_id.toLowerCase().includes(q) ||
          (s.command ?? '').toLowerCase().includes(q) ||
          (s.cwd ?? '').toLowerCase().includes(q)
        )
      }

      return result
    })
  }

  return { sessions, totalSessions, loading, error, fetchSessions, makeFiltered }
}
