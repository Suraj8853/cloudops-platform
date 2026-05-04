import { Router } from 'express'
import { nanoid } from 'nanoid'

export const router = Router()

// In-memory storage
const urls = {}

// POST /shorten — create short URL
router.post('/shorten', (req, res) => {
  const { url } = req.body

  if (!url) {
    return res.status(400).json({ error: 'URL is required' })
  }

  const shortCode = nanoid(6)
  urls[shortCode] = url

  res.json({
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
    return res.status(404).json({ error: 'Short URL not found' })
  }

  res.redirect(originalUrl)
})

// GET /urls — list all URLs (admin)
router.get('/urls', (req, res) => {
  res.json(urls)
})