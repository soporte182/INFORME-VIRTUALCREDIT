import { sqliteTable, text } from 'drizzle-orm/sqlite-core';
export const reports = sqliteTable('reports', { month: text('month').primaryKey(), payload: text('payload').notNull(), updatedAt: text('updated_at').notNull() });
