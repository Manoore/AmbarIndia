import { supabase } from './supabaseClient.js';

const STORE = 'ambar-reservations-v1';
const localRead = () => { try { const value = JSON.parse(localStorage.getItem(STORE)); return Array.isArray(value) ? value : []; } catch { return []; } };
const localWrite = (items) => localStorage.setItem(STORE, JSON.stringify(items));

export async function createReservation(input) {
  const reservation = { ...input, status: 'pending', created_at: new Date().toISOString() };
  if (!supabase) { const saved = { ...reservation, id: `local-${Date.now()}` }; localWrite([saved, ...localRead()]); return { reservation: saved, error: null }; }
  const { data, error } = await supabase.from('reservations').insert(reservation).select().single();
  if (error) return { reservation: null, error: error.message };
  return { reservation: data, error: null };
}

export async function listReservations(locationId = 'all') {
  if (!supabase) return { reservations: locationId === 'all' ? localRead() : localRead().filter((item) => item.location_id === locationId), error: null };
  let query = supabase.from('reservations').select('*').order('reservation_date', { ascending: true }).order('reservation_time', { ascending: true });
  if (locationId !== 'all') query = query.eq('location_id', locationId);
  const { data, error } = await query;
  return { reservations: data || [], error: error?.message || null };
}

export async function updateReservationStatus(id, status) {
  if (!supabase) { const next = localRead().map((item) => item.id === id ? { ...item, status } : item); localWrite(next); return { error: null }; }
  const { error } = await supabase.from('reservations').update({ status }).eq('id', id);
  return { error: error?.message || null };
}
