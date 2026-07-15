import { supabase } from './supabaseClient.js';

export const defaultTables = Array.from({ length: 12 }, (_, index) => ({ id: String(index + 1), label: `Table ${index + 1}`, seats: index < 4 ? 2 : index < 9 ? 4 : 6, active: true }));
const key = (locationId) => `ambar-tables-${locationId}`;
export async function loadLocationTables(locationId) { try { const cached = JSON.parse(localStorage.getItem(key(locationId))); if (Array.isArray(cached) && cached.length) return cached; } catch {} if (!supabase || !locationId) return defaultTables; const { data } = await supabase.from('locations').select('table_config').eq('id', locationId).maybeSingle(); return Array.isArray(data?.table_config) && data.table_config.length ? data.table_config : defaultTables; }
export async function saveLocationTables(locationId, tables) { localStorage.setItem(key(locationId), JSON.stringify(tables)); if (!supabase) return { error: null }; const { error } = await supabase.from('locations').update({ table_config: tables }).eq('id', locationId); return { error: error?.message || null }; }
