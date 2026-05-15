import Redis from 'ioredis'

const redis = new Redis({
  host: process.env.REDIS_HOST || 'redis',
  port: process.env.REDIS_PORT || 6379,
  lazyConnect: true,
  retryStrategy: (times) => {
    if (times > 3) return null  // stop retrying after 3 attempts
    return Math.min(times * 200, 2000)
  }
})

redis.on('connect', () => console.log('Redis connected'))
redis.on('error', (err) => console.log('Redis error:', err.message))

export default redis