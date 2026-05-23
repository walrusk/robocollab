import { Handle, Position, type NodeProps } from '@xyflow/react';
import type { SonicFlowNode } from '../types';

function fileName(path: string): string {
  const parts = path.split('/');
  return parts[parts.length - 1] || path;
}

export function SonicNode({ data, selected }: NodeProps<SonicFlowNode>) {
  const { node } = data;

  return (
    <div className={`sonic-node ${selected ? 'sonic-node-selected' : ''}`}>
      <Handle className="sonic-handle" type="target" position={Position.Left} />
      <div className="sonic-node-header">
        <span className="sonic-kind-dot" aria-hidden="true" />
        <span className="sonic-node-kind">{node.kind || 'module'}</span>
      </div>
      <div className="sonic-node-label">{node.label || node.id}</div>
      <div className="sonic-node-summary">{node.summary || 'No summary captured.'}</div>
      {node.representativeFile ? (
        <div className="sonic-node-file" title={node.representativeFile}>
          {fileName(node.representativeFile)}
        </div>
      ) : null}
      <Handle className="sonic-handle" type="source" position={Position.Right} />
    </div>
  );
}
