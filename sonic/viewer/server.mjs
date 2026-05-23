import express from 'express';
import { createServer as createHttpServer } from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawn } from 'node:child_process';
import { createServer as createViteServer } from 'vite';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(process.env.SONIC_PROJECT_ROOT || process.cwd());
const host = process.env.SONIC_HOST || '127.0.0.1';
const port = Number(process.env.SONIC_PORT || '5177');
const dataPath = path.resolve(projectRoot, process.env.SONIC_DATA_PATH || '.sonic/project-map.json');
const serveStatic = process.env.SONIC_SERVE_STATIC === '1';
const shouldOpenBrowser = process.env.SONIC_NO_OPEN !== '1';

const app = express();
app.use(express.json({ limit: '2mb' }));

function fallbackStore() {
  return {
    schemaVersion: 1,
    project: {
      name: path.basename(projectRoot),
      root: projectRoot,
      summary: 'No Sonic project map has been generated for this project yet.',
    },
    nodes: [],
    edges: [],
    notes: ['Run sonic before using the viewer to generate a project map.'],
    view: {
      positions: {},
    },
  };
}

function normalizeStore(raw) {
  const store = raw && typeof raw === 'object' ? raw : fallbackStore();

  return {
    schemaVersion: Number(store.schemaVersion || 1),
    project: {
      name: String(store.project?.name || path.basename(projectRoot)),
      root: String(store.project?.root || projectRoot),
      summary: String(store.project?.summary || ''),
    },
    nodes: Array.isArray(store.nodes) ? store.nodes : [],
    edges: Array.isArray(store.edges) ? store.edges : [],
    notes: Array.isArray(store.notes) ? store.notes : [],
    view: {
      positions:
        store.view?.positions && typeof store.view.positions === 'object'
          ? store.view.positions
          : {},
      viewport:
        store.view?.viewport && typeof store.view.viewport === 'object'
          ? store.view.viewport
          : undefined,
    },
  };
}

async function readStore() {
  try {
    const content = await fs.readFile(dataPath, 'utf8');
    return normalizeStore(JSON.parse(content));
  } catch (error) {
    if (error && error.code === 'ENOENT') {
      return fallbackStore();
    }

    throw error;
  }
}

async function writeStore(store) {
  await fs.mkdir(path.dirname(dataPath), { recursive: true });
  await fs.writeFile(dataPath, `${JSON.stringify(normalizeStore(store), null, 2)}\n`);
}

function openBrowser(url) {
  if (!shouldOpenBrowser) {
    return;
  }

  const platform = process.platform;
  const command =
    platform === 'darwin'
      ? 'open'
      : platform === 'win32'
        ? 'cmd'
        : 'xdg-open';
  const args = platform === 'win32' ? ['/c', 'start', '', url] : [url];
  const child = spawn(command, args, { detached: true, stdio: 'ignore' });
  child.unref();
}

app.get('/api/store', async (_request, response, next) => {
  try {
    response.json(await readStore());
  } catch (error) {
    next(error);
  }
});

app.put('/api/store', async (request, response, next) => {
  try {
    await writeStore(request.body);
    response.json(await readStore());
  } catch (error) {
    next(error);
  }
});

app.patch('/api/view', async (request, response, next) => {
  try {
    const store = await readStore();
    store.view = {
      ...store.view,
      ...request.body,
      positions: {
        ...(store.view?.positions || {}),
        ...(request.body?.positions || {}),
      },
    };
    await writeStore(store);
    response.json(store.view);
  } catch (error) {
    next(error);
  }
});

app.use('/api', (_request, response) => {
  response.status(404).json({ error: 'Not found' });
});

const httpServer = createHttpServer(app);

if (serveStatic) {
  app.use(express.static(path.join(__dirname, 'dist')));
  app.use((_request, response) => {
    response.sendFile(path.join(__dirname, 'dist', 'index.html'));
  });
} else {
  const vite = await createViteServer({
    root: __dirname,
    server: {
      middlewareMode: true,
      hmr: {
        server: httpServer,
      },
    },
    appType: 'spa',
  });
  app.use(vite.middlewares);
}

app.use((error, _request, response, _next) => {
  console.error(error);
  response.status(500).json({ error: error instanceof Error ? error.message : 'Unknown error' });
});

httpServer.listen(port, host, () => {
  const url = `http://${host}:${port}`;
  console.log(`Sonic viewer running at ${url}`);
  console.log(`Data store: ${dataPath}`);
  openBrowser(url);
});
