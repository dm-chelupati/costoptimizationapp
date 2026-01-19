/**
 * Todo API - A working app connected to Azure Storage
 */

const express = require('express');
const { DefaultAzureCredential } = require('@azure/identity');
const { BlobServiceClient } = require('@azure/storage-blob');

const app = express();
app.use(express.json());

// In-memory todo storage
let todos = [];
let nextId = 1;

// Azure clients
let blobContainerClient = null;

// Initialize Azure connections
async function initializeAzureClients() {
  const credential = new DefaultAzureCredential();

  const storageAccountName = process.env.AZURE_STORAGE_ACCOUNT_NAME;
  if (storageAccountName) {
    try {
      const blobServiceClient = new BlobServiceClient(
        `https://${storageAccountName}.blob.core.windows.net`,
        credential
      );
      blobContainerClient = blobServiceClient.getContainerClient('data');
      await blobContainerClient.createIfNotExists();
      console.log(`✅ Connected to Storage: ${storageAccountName}`);
    } catch (err) {
      console.warn(`⚠️ Could not connect to storage: ${err.message}`);
    }
  }

  console.log('\n🚀 Azure integrations initialized');
}

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    app: 'Todo API',
    version: '1.0.0',
    connections: {
      storage: blobContainerClient !== null
    }
  });
});

// GET /todos
app.get('/todos', (req, res) => {
  res.json({ count: todos.length, items: todos });
});

// GET /todos/:id
app.get('/todos/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const todo = todos.find(t => t.id === id);
  if (!todo) return res.status(404).json({ error: 'Todo not found' });
  res.json(todo);
});

// POST /todos
app.post('/todos', async (req, res) => {
  const { title, description } = req.body;
  if (!title) return res.status(400).json({ error: 'Title is required' });

  const todo = {
    id: nextId++,
    title,
    description: description || '',
    completed: false,
    createdAt: new Date().toISOString()
  };

  todos.push(todo);

  if (blobContainerClient) {
    try {
      const blobClient = blobContainerClient.getBlockBlobClient(`todos/${todo.id}.json`);
      await blobClient.upload(JSON.stringify(todo), JSON.stringify(todo).length, {
        blobHTTPHeaders: { blobContentType: 'application/json' }
      });
    } catch (err) {
      console.warn(`Could not store todo in blob: ${err.message}`);
    }
  }

  res.status(201).json(todo);
});

// PUT /todos/:id
app.put('/todos/:id', async (req, res) => {
  const id = parseInt(req.params.id);
  const todoIndex = todos.findIndex(t => t.id === id);
  if (todoIndex === -1) return res.status(404).json({ error: 'Todo not found' });

  const { title, description, completed } = req.body;
  const todo = todos[todoIndex];
  
  if (title !== undefined) todo.title = title;
  if (description !== undefined) todo.description = description;
  if (completed !== undefined) todo.completed = completed;
  todo.updatedAt = new Date().toISOString();

  if (blobContainerClient) {
    try {
      const blobClient = blobContainerClient.getBlockBlobClient(`todos/${todo.id}.json`);
      await blobClient.upload(JSON.stringify(todo), JSON.stringify(todo).length, {
        blobHTTPHeaders: { blobContentType: 'application/json' },
        overwrite: true
      });
    } catch (err) {
      console.warn(`Could not update todo in blob: ${err.message}`);
    }
  }

  res.json(todo);
});

// DELETE /todos/:id
app.delete('/todos/:id', async (req, res) => {
  const id = parseInt(req.params.id);
  const todoIndex = todos.findIndex(t => t.id === id);
  if (todoIndex === -1) return res.status(404).json({ error: 'Todo not found' });

  const [deleted] = todos.splice(todoIndex, 1);

  if (blobContainerClient) {
    try {
      const blobClient = blobContainerClient.getBlockBlobClient(`todos/${id}.json`);
      await blobClient.deleteIfExists();
    } catch (err) {
      console.warn(`Could not delete todo from blob: ${err.message}`);
    }
  }

  res.json({ message: 'Todo deleted', todo: deleted });
});

// Landing page
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Todo API</title>
      <style>
        body { font-family: system-ui, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; }
        h1 { color: #0078d4; }
        .card { background: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0; }
        code { background: #e1e1e1; padding: 2px 6px; border-radius: 4px; }
        a { color: #0078d4; }
      </style>
    </head>
    <body>
      <h1>✅ Todo API</h1>
      <p>A simple Todo application running on Azure App Service.</p>

      <div class="card">
        <h3>API Endpoints</h3>
        <ul>
          <li><code>GET</code> <a href="/health">/health</a> - Health check</li>
          <li><code>GET</code> <a href="/todos">/todos</a> - List all todos</li>
          <li><code>POST</code> /todos - Create a todo</li>
          <li><code>PUT</code> /todos/:id - Update a todo</li>
          <li><code>DELETE</code> /todos/:id - Delete a todo</li>
        </ul>
      </div>

      <div class="card">
        <h3>Try it out</h3>
        <p>Create a todo:</p>
        <code>curl -X POST -H "Content-Type: application/json" -d '{"title":"My first todo"}' ${req.protocol}://${req.get('host')}/todos</code>
      </div>
    </body>
    </html>
  `);
});

// Start server
const PORT = process.env.PORT || 3000;

initializeAzureClients()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`\n🎯 Todo API listening on port ${PORT}`);
    });
  })
  .catch(err => {
    console.error('Failed to initialize:', err);
    app.listen(PORT, () => {
      console.log(`\n🎯 Todo API listening on port ${PORT} (without Azure integrations)`);
    });
  });
