import { createRouter, createWebHistory } from 'vue-router'
import HomePage from '../pages/HomePage.vue'
import SessionsPage from '../pages/SessionsPage.vue'
import SessionDetailPage from '../pages/SessionDetailPage.vue'
import ToolsPage from '../pages/ToolsPage.vue'

const routes = [
  { path: '/', component: HomePage, meta: { title: 'Home' } },
  { path: '/sessions', component: SessionsPage, meta: { title: 'Sessions' } },
  { path: '/sessions/:sessionId', component: SessionDetailPage, meta: { title: 'Session' } },
  { path: '/tools', component: ToolsPage, meta: { title: 'Tools' } },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.afterEach((to) => {
  const title = to.meta?.title
  document.title = title ? `mec dashboard — ${title}` : 'mec dashboard'
})

export default router
