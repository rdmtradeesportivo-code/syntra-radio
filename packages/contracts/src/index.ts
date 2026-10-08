export type StudioAgentStatus = "offline" | "online" | "degraded";

export type StudioCapabilities = {
  audioOutputs: string[];
  audioInputs: string[];
  canStream: boolean;
  canRecord: boolean;
  canPlayLocalCache: boolean;
};

export type StudioHeartbeat = {
  deviceId: string;
  stationId: string;
  status: StudioAgentStatus;
  version: string;
  capabilities: StudioCapabilities;
  observedAt: string;
};

export type QueueItem = {
  id: string;
  mediaAssetId: string;
  title: string;
  artist?: string;
  durationMs?: number;
  cueInMs: number;
  cueOutMs?: number;
};

export type PublishedSchedule = {
  stationId: string;
  revision: string;
  generatedAt: string;
  validFrom: string;
  validUntil: string;
  queue: QueueItem[];
};
