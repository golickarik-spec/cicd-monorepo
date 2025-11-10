import { useEffect, useState } from 'react'

function App() {
  const [items, setItems] = useState([])
  const [name, setName] = useState('')
  const [loading, setLoading] = useState(false)

  async function fetchItems() {
    setLoading(true)
    const res = await fetch('/api/items')
    const data = await res.json()
    setItems(data)
    setLoading(false)
  }

  useEffect(() => { fetchItems() }, [])

  async function addItem(e) {
    e.preventDefault()
    if (!name.trim()) return
    await fetch('/api/items', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name })
    })
    setName('')
    fetchItems()
  }

  async function removeItem(id) {
    await fetch(`/api/items/${id}`, { method: 'DELETE' })
    fetchItems()
  }

  return (
    <div style={{ maxWidth: 600, margin: '40px auto', fontFamily: 'sans-serif' }}>
      <h1>Items</h1>
      <form onSubmit={addItem} style={{ marginBottom: 16 }}>
        <input value={name} onChange={(e) => setName(e.target.value)} placeholder="New item name" />
        <button type="submit" style={{ marginLeft: 8 }}>Add</button>
      </form>
      {loading ? <p>Loading...</p> : (
        <ul>
          {items.map(it => (
            <li key={it.id}>
              {it.name}
              <button onClick={() => removeItem(it.id)} style={{ marginLeft: 8 }}>Delete</button>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}

export default App


