import { FileCode, Layers, LogIn, LogOut, Route, Workflow } from 'lucide-react';
import type { SonicIo, SonicNode, SonicStore } from '../types';

type Props = {
  node: SonicNode | null;
  store: SonicStore;
};

function ValueList({ values }: { values: string[] }) {
  if (values.length === 0) {
    return <span className="muted">None captured</span>;
  }

  return (
    <div className="chip-row">
      {values.map((value) => (
        <span className="chip" key={value}>
          {value}
        </span>
      ))}
    </div>
  );
}

function IoList({ items, emptyLabel }: { items: SonicIo[]; emptyLabel: string }) {
  if (items.length === 0) {
    return <span className="muted">{emptyLabel}</span>;
  }

  return (
    <div className="io-list">
      {items.map((item, index) => (
        <div className="io-row" key={`${item.name}-${index}`}>
          <span>{item.name}</span>
          <small>{item.kind || item.source || item.destination}</small>
        </div>
      ))}
    </div>
  );
}

export function DetailsPanel({ node, store }: Props) {
  if (!node) {
    return (
      <aside className="details-panel">
        <div className="details-empty">
          <Workflow size={22} aria-hidden="true" />
          <h2>{store.project.name}</h2>
          <p>{store.project.summary || 'Select a node to inspect the captured project details.'}</p>
          <dl className="project-stats">
            <div>
              <dt>Nodes</dt>
              <dd>{store.nodes.length}</dd>
            </div>
            <div>
              <dt>Edges</dt>
              <dd>{store.edges.length}</dd>
            </div>
          </dl>
        </div>
      </aside>
    );
  }

  return (
    <aside className="details-panel">
      <div className="details-heading">
        <span className="kind-pill">{node.kind || 'module'}</span>
        <h2>{node.label}</h2>
        <p>{node.summary || 'No summary captured.'}</p>
      </div>

      <section className="details-section">
        <h3>
          <FileCode size={16} aria-hidden="true" />
          Representative File
        </h3>
        <code>{node.representativeFile || 'None captured'}</code>
      </section>

      <section className="details-section">
        <h3>
          <Route size={16} aria-hidden="true" />
          Entrypoints
        </h3>
        <ValueList values={node.entrypoints} />
      </section>

      <section className="details-section">
        <h3>
          <Layers size={16} aria-hidden="true" />
          Technologies
        </h3>
        <ValueList values={node.technologies} />
      </section>

      <section className="details-section">
        <h3>
          <LogIn size={16} aria-hidden="true" />
          Inputs
        </h3>
        <IoList items={node.inputs} emptyLabel="No inputs captured" />
      </section>

      <section className="details-section">
        <h3>
          <LogOut size={16} aria-hidden="true" />
          Outputs
        </h3>
        <IoList items={node.outputs} emptyLabel="No outputs captured" />
      </section>
    </aside>
  );
}
