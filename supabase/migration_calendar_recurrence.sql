-- Migración para soporte de repetición unificada en calendario (Fase 1)
-- Columna recurrence en schedules: '' = único, 'weekly:1,3,5', 'every:N', 'monthly', 'yearly'
ALTER TABLE schedules ADD COLUMN IF NOT EXISTS recurrence TEXT DEFAULT '';
