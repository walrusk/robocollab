import '@xyflow/react/dist/style.css';
import {
  Background,
  BackgroundVariant,
  Controls,
  MiniMap,
  Panel,
  ReactFlow,
  ReactFlowProvider,
  useEdgesState,
  useNodesState,
  useReactFlow,
  type Edge,
  type NodeMouseHandler,
} from '@xyflow/react';
import { RefreshCw, Save, ZoomIn } from 'lucide-react';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { getStore, saveViewState } from './api';
import { DetailsPanel } from './components/DetailsPanel';
import { SonicNode } from './components/SonicNode';
import { toFlowEdges, toFlowNodes } from './graph';
import type { SonicFlowNode, SonicNode as SonicNodeData, SonicStore } from './types';

const nodeTypes = {
  sonicNode: SonicNode,
};

function Viewer() {
  const [store, setStore] = useState<SonicStore | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [selectedNode, setSelectedNode] = useState<SonicNodeData | null>(null);
  const [isSaving, setIsSaving] = useState(false);
  const [nodes, setNodes, onNodesChange] = useNodesState<SonicFlowNode>([]);
  const [edges, setEdges, onEdgesChange] = useEdgesState<Edge>([]);
  const reactFlow = useReactFlow();

  const loadStore = useCallback(async () => {
    setLoadError(null);
    const nextStore = await getStore();
    setStore(nextStore);
    setNodes(toFlowNodes(nextStore));
    setEdges(toFlowEdges(nextStore));
    setSelectedNode(null);
    window.setTimeout(() => reactFlow.fitView({ padding: 0.18, duration: 250 }), 0);
  }, [reactFlow, setEdges, setNodes]);

  useEffect(() => {
    loadStore().catch((error: unknown) => {
      setLoadError(error instanceof Error ? error.message : 'Could not load Sonic graph.');
    });
  }, [loadStore]);

  const onNodeClick: NodeMouseHandler<SonicFlowNode> = useCallback((_event, node) => {
    setSelectedNode(node.data.node);
  }, []);

  const persistLayout = useCallback(async () => {
    setIsSaving(true);
    try {
      const positions = Object.fromEntries(
        nodes.map((node) => [node.id, { x: Math.round(node.position.x), y: Math.round(node.position.y) }]),
      );
      await saveViewState({ positions, viewport: reactFlow.getViewport() });
    } finally {
      setIsSaving(false);
    }
  }, [nodes, reactFlow]);

  const hasGraph = Boolean(store && store.nodes.length > 0);
  const nodeCount = store?.nodes.length || 0;
  const edgeCount = store?.edges.length || 0;

  const minimapColor = useMemo(
    () => (node: SonicFlowNode) => {
      const kind = node.data.node.kind.toLowerCase();
      if (kind === 'app') return '#0f766e';
      if (kind === 'service') return '#7c3aed';
      if (kind === 'config') return '#d97706';
      if (kind === 'workflow' || kind === 'script') return '#2563eb';
      return '#334155';
    },
    [],
  );

  if (loadError) {
    return (
      <main className="app-shell">
        <div className="error-state">
          <h1>Sonic could not load the project map</h1>
          <p>{loadError}</p>
          <button className="text-button" type="button" onClick={() => void loadStore()}>
            <RefreshCw size={16} aria-hidden="true" />
            Retry
          </button>
        </div>
      </main>
    );
  }

  if (!store) {
    return (
      <main className="app-shell">
        <div className="loading-state">Loading Sonic project map...</div>
      </main>
    );
  }

  return (
    <main className="app-shell">
      <section className="graph-region" aria-label="Project graph">
        <ReactFlow
          nodes={nodes}
          edges={edges}
          nodeTypes={nodeTypes}
          onNodesChange={onNodesChange}
          onEdgesChange={onEdgesChange}
          onNodeClick={onNodeClick}
          onPaneClick={() => setSelectedNode(null)}
          fitView
          minZoom={0.18}
          maxZoom={1.8}
        >
          <Background color="#c8ced8" gap={22} size={1.2} variant={BackgroundVariant.Dots} />
          <Controls showInteractive={false} />
          <MiniMap nodeColor={minimapColor} pannable zoomable />
          <Panel position="top-left">
            <div className="topbar">
              <div>
                <p className="eyebrow">Sonic map</p>
                <h1>{store.project.name}</h1>
              </div>
              <div className="topbar-meta">
                <span>{nodeCount} nodes</span>
                <span>{edgeCount} edges</span>
              </div>
              <div className="topbar-actions">
                <button className="icon-button" type="button" onClick={() => reactFlow.fitView({ padding: 0.18 })} title="Fit graph">
                  <ZoomIn size={18} aria-hidden="true" />
                </button>
                <button className="icon-button" type="button" onClick={() => void loadStore()} title="Reload data">
                  <RefreshCw size={18} aria-hidden="true" />
                </button>
                <button className="text-button" type="button" onClick={() => void persistLayout()} disabled={isSaving} title="Save node positions">
                  <Save size={16} aria-hidden="true" />
                  {isSaving ? 'Saving' : 'Save layout'}
                </button>
              </div>
            </div>
          </Panel>
          {!hasGraph ? (
            <Panel position="top-center">
              <div className="empty-graph">No graph data yet. Run Sonic once, then refresh this viewer.</div>
            </Panel>
          ) : null}
        </ReactFlow>
      </section>
      <DetailsPanel node={selectedNode} store={store} />
    </main>
  );
}

export default function App() {
  return (
    <ReactFlowProvider>
      <Viewer />
    </ReactFlowProvider>
  );
}
