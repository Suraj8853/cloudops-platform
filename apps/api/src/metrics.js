import client from 'prom-client'

// Enable default metrics (CPU, memory, event loop, etc.)
const register = new client.Registry()
client.collectDefaultMetrics({ register })

// Custom metric 1 — request counter
export const httpRequestsTotal = new client.Counter({
  name: 'url_shortener_requests_total',
  help: 'Total number of requests by route and status code',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register],
})

// Custom metric 2 — redirect duration histogram
export const redirectDuration = new client.Histogram({
  name: 'url_shortener_redirect_duration_seconds',
  help: 'Duration of redirect requests in seconds',
  labelNames: ['status_code'],
  buckets: [0.01, 0.05, 0.1, 0.3, 0.5, 1, 2],
  registers: [register],
})

export { register }