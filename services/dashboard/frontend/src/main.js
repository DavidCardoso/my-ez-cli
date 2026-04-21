import { createApp } from 'vue'
import PrimeVue from 'primevue/config'
import Aura from '@primevue/themes/aura'
import Tooltip from 'primevue/tooltip'
import router from './router/index.js'
import App from './App.vue'
import 'primeicons/primeicons.css'
import './assets/main.css'

const app = createApp(App)

app.use(router)
app.use(PrimeVue, {
  theme: {
    preset: Aura,
    options: {
      darkModeSelector: '.p-dark',
      cssLayer: false,
    },
  },
})
app.directive('tooltip', Tooltip)
app.mount('#app')
