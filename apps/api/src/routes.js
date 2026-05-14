import { Router } from 'express'
import { nanoid } from 'nanoid'
import { httpRequestsTotal, redirectDuration } from './metrics.js'

export const router = Router()

// In-memory storage
const urls = {}

// POST /shorten — create short URL
router.post('/shorten', (req, res) => {
  const { url } = req.body

  if (!url) {
    httpRequestsTotal.inc({ method: 'POST', route: '/shorten', status_code: 400 })
    return res.status(400).json({ error: 'URL is required' })
  }

  const shortCode = nanoid(6)
  urls[shortCode] = url

  httpRequestsTotal.inc({ method: 'POST', route: '/shorten', status_code: 201 })
  res.status(201).json({
    shortCode,
    shortUrl: `${process.env.BASE_URL || 'http://localhost:3000'}/${shortCode}`,
    originalUrl: url
  })
})

// GET /:shortCode — redirect to original URL
router.get('/:shortCode', (req, res) => {
  const { shortCode } = req.params
  const originalUrl = urls[shortCode]

  if (!originalUrl) {
    httpRequestsTotal.inc({ method: 'GET', route: '/:shortCode', status_code: 404 })
    return res.status(404).json({ error: 'Short URL not found' })
  }

  const end = redirectDuration.startTimer()
  httpRequestsTotal.inc({ method: 'GET', route: '/:shortCode', status_code: 302 })
  end({ status_code: 302 })

  res.redirect(originalUrl)
})

// GET /urls — list all URLs (admin)
router.get('/urls', (req, res) => {
  httpRequestsTotal.inc({ method: 'GET', route: '/urls', status_code: 200 })
  res.json(urls)
})