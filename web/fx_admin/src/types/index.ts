export interface App {
  id: string;
  name: string;
  description: string | null;
  created_at: string;
}

export interface AppVersion {
  id: number;
  platform: string;
  version: string;
  download_url: string;
  file_size: number;
  sha256: string | null;
  release_notes: string | null;
  force_update: boolean;
  published: boolean;
  created_at: string;
}

export interface CreateAppPayload {
  id: string;
  name: string;
  description?: string;
}

export interface CreateVersionPayload {
  app_id: string;
  platform: string;
  version: string;
  download_url: string;
  file_size?: number;
  sha256?: string;
  release_notes?: string;
  force_update?: boolean;
}

export interface UpdateVersionPayload {
  download_url?: string;
  file_size?: number;
  sha256?: string;
  release_notes?: string;
  force_update?: boolean;
}
