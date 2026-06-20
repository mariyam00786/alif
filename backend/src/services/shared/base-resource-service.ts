import { getSupabaseClient } from '../../config/supabase';
import { HttpError } from '../../errors/http-error';
import type { AuthenticatedUser } from '../../types/domain';
import { AuditLogService } from '../audit/audit-log-service';

type ResourceRecord = Record<string, unknown>;

export class BaseResourceService {
  constructor(
    private readonly tableName: string,
    private readonly entityType: string,
    private readonly auditLogService: AuditLogService = new AuditLogService()
  ) {}

  async list(orderColumn = 'created_at'): Promise<ResourceRecord[]> {
    const { data, error } = await getSupabaseClient()
      .from(this.tableName)
      .select('*')
      .order(orderColumn, { ascending: false });

    if (error) {
      throw new HttpError(500, `Unable to fetch ${this.entityType} records.`, error);
    }

    return (data ?? []) as ResourceRecord[];
  }

  async getById(id: string): Promise<ResourceRecord> {
    const { data, error } = await getSupabaseClient()
      .from(this.tableName)
      .select('*')
      .eq('id', id)
      .maybeSingle();

    if (error) {
      throw new HttpError(500, `Unable to fetch ${this.entityType}.`, error);
    }

    if (!data) {
      throw new HttpError(404, `${this.entityType} not found.`);
    }

    return data as ResourceRecord;
  }

  async create(payload: ResourceRecord, actor?: AuthenticatedUser): Promise<ResourceRecord> {
    const { data, error } = await getSupabaseClient()
      .from(this.tableName)
      .insert(payload)
      .select('*')
      .single();

    if (error) {
      throw new HttpError(500, `Unable to create ${this.entityType}.`, error);
    }

    await this.auditLogService.log({
      actor,
      action: 'create',
      entityType: this.entityType,
      entityId: String((data as ResourceRecord).id ?? ''),
      metadata: payload,
    });

    return data as ResourceRecord;
  }

  async update(id: string, payload: ResourceRecord, actor?: AuthenticatedUser): Promise<ResourceRecord> {
    const updatePayload = {
      ...payload,
      updated_at: new Date().toISOString(),
    };

    const { data, error } = await getSupabaseClient()
      .from(this.tableName)
      .update(updatePayload)
      .eq('id', id)
      .select('*')
      .maybeSingle();

    if (error) {
      throw new HttpError(500, `Unable to update ${this.entityType}.`, error);
    }

    if (!data) {
      throw new HttpError(404, `${this.entityType} not found.`);
    }

    await this.auditLogService.log({
      actor,
      action: 'update',
      entityType: this.entityType,
      entityId: id,
      metadata: payload,
    });

    return data as ResourceRecord;
  }
}