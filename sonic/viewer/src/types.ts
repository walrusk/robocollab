export type SonicIo = {
  name: string;
  kind: string;
  source?: string;
  destination?: string;
};

export type SonicNode = {
  id: string;
  type: string;
  label: string;
  kind: string;
  summary: string;
  representativeFile: string;
  entrypoints: string[];
  technologies: string[];
  inputs: SonicIo[];
  outputs: SonicIo[];
};

export type SonicEdge = {
  id: string;
  source: string;
  target: string;
  label: string;
  relationship: string;
};

export type SonicStore = {
  schemaVersion: number;
  project: {
    name: string;
    root: string;
    summary: string;
  };
  nodes: SonicNode[];
  edges: SonicEdge[];
  notes: string[];
  view?: {
    positions?: Record<string, { x: number; y: number }>;
    viewport?: { x: number; y: number; zoom: number };
  };
};

export type GraphNodeData = Record<string, unknown> & {
  node: SonicNode;
};

export type SonicFlowNode = Node<GraphNodeData, 'sonicNode'>;
import type { Node } from '@xyflow/react';
