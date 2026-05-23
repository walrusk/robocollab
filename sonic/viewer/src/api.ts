import type { SonicStore } from './types';

async function parseJsonResponse<T>(response: Response): Promise<T> {
  if (!response.ok) {
    const message = await response.text();
    throw new Error(message || `Request failed with ${response.status}`);
  }

  return response.json() as Promise<T>;
}

export async function getStore(): Promise<SonicStore> {
  const response = await fetch('/api/store');
  return parseJsonResponse<SonicStore>(response);
}

export async function saveViewState(view: NonNullable<SonicStore['view']>): Promise<void> {
  const response = await fetch('/api/view', {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(view),
  });

  await parseJsonResponse(response);
}
