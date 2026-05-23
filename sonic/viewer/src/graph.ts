import dagre from '@dagrejs/dagre';
import { MarkerType, type Edge } from '@xyflow/react';
import type { SonicFlowNode, SonicStore } from './types';

const NODE_WIDTH = 280;
const NODE_HEIGHT = 154;

function kindClass(kind: string): string {
  const normalized = kind.toLowerCase().replace(/[^a-z0-9]+/g, '-');
  return normalized || 'module';
}

export function toFlowNodes(store: SonicStore): SonicFlowNode[] {
  const graph = new dagre.graphlib.Graph();
  graph.setDefaultEdgeLabel(() => ({}));
  graph.setGraph({ rankdir: 'LR', nodesep: 72, ranksep: 130, marginx: 40, marginy: 40 });

  store.nodes.forEach((node) => {
    graph.setNode(node.id, { width: NODE_WIDTH, height: NODE_HEIGHT });
  });

  store.edges.forEach((edge) => {
    graph.setEdge(edge.source, edge.target);
  });

  dagre.layout(graph);

  return store.nodes.map((node) => {
    const storedPosition = store.view?.positions?.[node.id];
    const layoutNode = graph.node(node.id);
    const position = storedPosition || {
      x: (layoutNode?.x || 0) - NODE_WIDTH / 2,
      y: (layoutNode?.y || 0) - NODE_HEIGHT / 2,
    };

    return {
      id: node.id,
      type: 'sonicNode',
      className: `sonic-node-${kindClass(node.kind)}`,
      position,
      data: { node },
    };
  });
}

export function toFlowEdges(store: SonicStore): Edge[] {
  return store.edges.map((edge) => ({
    id: edge.id,
    source: edge.source,
    target: edge.target,
    label: edge.label || edge.relationship,
    type: 'smoothstep',
    markerEnd: {
      type: MarkerType.ArrowClosed,
      width: 18,
      height: 18,
    },
    data: {
      relationship: edge.relationship,
    },
  }));
}
