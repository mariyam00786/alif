import type { AuthenticatedUser } from '../../types/domain';
import { getSupabaseClient } from '../../config/supabase';

interface AuditLogInput {
  actor?: AuthenticatedUser;
  action: string;
  entityType: string;
  entityId?: string;
  metadata?: Record<string, unknown>;
}

export class AuditLogService {
  async log(input: AuditLogInput): Promise<void> {
    const { error } = await getSupabaseClient()
      .from('audit_logs')
      .insert({
        actor_profile_id: input.actor?.profileId ?? null,
        action: input.action,
        entity_type: input.entityType,
        entity_id: input.entityId ?? null,
        metadata: input.metadata ?? {},
      });

    if (error) {
      console.error('Failed to write audit log', error);
    }
  }
}