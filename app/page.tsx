'use client'

import { useState, useEffect } from 'react'

interface ApiData {
  message: string
  timestamp: string
  version: string
}

export default function Home() {
  const [data, setData] = useState<ApiData | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fetchData = async () => {
    setLoading(true)
    setError(null)
    try {
      const response = await fetch('/api/data')
      if (!response.ok) {
        throw new Error('Failed to fetch data')
      }
      const result = await response.json()
      setData(result)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchData()
  }, [])

  return (
    <div className="container">
      <h1>Next.js 15 Simple App</h1>
      <p>Welcome to your Next.js 15 TypeScript application!</p>
      
      <div className="card">
        <h2>API Data</h2>
        <button 
          className="button" 
          onClick={fetchData}
          disabled={loading}
        >
          {loading ? 'Loading...' : 'Refresh Data'}
        </button>
        
        {error && (
          <div style={{ color: 'red', marginTop: '1rem' }}>
            Error: {error}
          </div>
        )}
        
        {data && (
          <div style={{ marginTop: '1rem' }}>
            <p><strong>Message:</strong> {data.message}</p>
            <p><strong>Timestamp:</strong> {data.timestamp}</p>
            <p><strong>Version:</strong> {data.version}</p>
          </div>
        )}
      </div>
      
      <div className="card">
        <h2>Features</h2>
        <ul>
          <li>Next.js 15 with TypeScript</li>
          <li>Standalone build configuration</li>
          <li>Simple API endpoint</li>
          <li>Modern React with hooks</li>
          <li>Responsive design</li>
        </ul>
      </div>
    </div>
  )
}
