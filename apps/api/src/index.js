import express from 'express'
import cors from 'cors'
import dotenv from 'dotenv'
import { router } from './routes.js'
import { register } from './metrics.js'

dotenv.config()

const app = express()
const PORT = process.env.PORT || 3000

app.use(cors())
app.use(express.json())

// Health checks FIRST — before router
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() })
})

app.get('/ready', (req, res) => {
  res.json({ status: 'ready', timestamp: new Date().toISOString() })
})

// Metrics endpoint — for Prometheus scraping
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType)
  res.end(await register.metrics())
})

// Router AFTER health checks
app.use('/', router)

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`)
})

export default app