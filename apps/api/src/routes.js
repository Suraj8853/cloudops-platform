import { Router } from 'express'
import { nanoid } from 'nanoid'
import { httpRequestsTotal, redirectDuration } from './metrics.js'
import redis from './redis.js'

export const router = Router()

// POST /shorten — create short URL
router.post('/shorten', async (req, res) => {
  const { url } = req.body

  if (!url) {
    httpRequestsTotal.inc({ method: 'POST', route: '/shorten', status_code: 400 })
    return res.status(400).json({ error: 'URL is required' })
  }

  const shortCode = nanoid(6)
  
  // Store in Redis with 24h expiry
  await redis.set(shortCode, url, 'EX', 86400)

  httpRequestsTotal.inc({ method: 'POST', route: '/shorten', status_code: 201 })
  res.status(201).json({
    shortCode,
    shortUrl: `${process.env.BASE_URL || 'http://localhost:3000'}/${shortCode}`,
    originalUrl: url
  })
})

// GET /:shortCode — redirect to original URL
router.get('/:shortCode', async (req, res) => {
  const { shortCode } = req.params

  const end = redirectDuration.startTimer()

  // Check Redis cache first
  const originalUrl = await redis.get(shortCode)

  if (!originalUrl) {
    httpRequestsTotal.inc({ method: 'GET', route: '/:shortCode', status_code: 404 })
    end({ status_code: 404 })
    return res.status(404).json({ error: 'Short URL not found' })
  }

  httpRequestsTotal.inc({ method: 'GET', route: '/:shortCode', status_code: 302 })
  end({ status_code: 302 })
  res.redirect(originalUrl)
})

// GET /urls — list all URLs (admin)
router.get('/urls', async (req, res) => {
  httpRequestsTotal.inc({ method: 'GET', route: '/urls', status_code: 200 })
  const keys = await redis.keys('*')
  const urls = {}
  for (const key of keys) {
    urls[key] = await redis.get(key)
  }
  res.json(urls)
})