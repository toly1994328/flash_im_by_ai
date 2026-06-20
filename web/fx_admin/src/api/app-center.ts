import type { App, AppVersion, CreateAppPayload, CreateVersionPayload, UpdateVersionPayload } from '../types';

const BASE = '/api';

export async function fetchApps(): Promise<App[]> {
  const res = await fetch(`${BASE}/app/list`);
  if (!res.ok) throw new Error('Failed to fetch apps');
  return res.json();
}

export async function createApp(payload: CreateAppPayload): Promise<void> {
  const res = await fetch(`${BASE}/app`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    throw new Error(data.error || 'Failed to create app');
  }
}

export async function fetchVersions(appId: string): Promise<AppVersion[]> {
  const res = await fetch(`${BASE}/app/versions?app_id=${appId}`);
  if (!res.ok) throw new Error('Failed to fetch versions');
  return res.json();
}

export async function createVersion(payload: CreateVersionPayload): Promise<void> {
  const body = {
    ...payload,
    file_size: payload.file_size ? Number(payload.file_size) : 0,
  };
  const res = await fetch(`${BASE}/app/version`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    throw new Error(data.error || 'Failed to create version');
  }
}

export async function updateVersion(
  appId: string, platform: string, version: string,
  payload: UpdateVersionPayload
): Promise<void> {
  const body = {
    ...payload,
    file_size: payload.file_size !== undefined ? Number(payload.file_size) : undefined,
  };
  const params = new URLSearchParams({ app_id: appId, platform, version });
  const res = await fetch(`${BASE}/app/version?${params}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    throw new Error(data.error || 'Failed to update version');
  }
}

export async function publishVersion(appId: string, platform: string, version: string): Promise<void> {
  const params = new URLSearchParams({ app_id: appId, platform, version });
  const res = await fetch(`${BASE}/app/version/publish?${params}`, { method: 'POST' });
  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    throw new Error(data.error || 'Failed to publish version');
  }
}

export async function unpublishVersion(appId: string, platform: string, version: string): Promise<void> {
  const params = new URLSearchParams({ app_id: appId, platform, version });
  const res = await fetch(`${BASE}/app/version/unpublish?${params}`, { method: 'POST' });
  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    throw new Error(data.error || 'Failed to unpublish version');
  }
}

export async function deleteVersion(appId: string, platform: string, version: string): Promise<void> {
  const params = new URLSearchParams({ app_id: appId, platform, version });
  const res = await fetch(`${BASE}/app/version?${params}`, { method: 'DELETE' });
  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    throw new Error(data.error || 'Failed to delete version');
  }
}
