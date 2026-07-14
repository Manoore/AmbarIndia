export const LOCATION_STORE = 'ambar-location-demo-v1';

export const starterLocations = [
  { id: 'clifton', name: 'Ambar India Clifton', address: '350 Ludlow Ave, Cincinnati, OH 45220', phone: '(513) 281-7000', services: ['dine-in', 'pickup', 'delivery', 'catering'], hours: { sunday: '10:30 AM – 9:30 PM', weekday: '10:30 AM – 10:00 PM', saturday: '10:30 AM – 10:00 PM' }, rewardOffer: 'Free Garlic Naan with orders over $35', menuNote: 'Our complete Clifton menu, made fresh to order.' },
  { id: 'downtown', name: 'Ambar India Downtown', address: 'Location being planned', phone: '', services: ['pickup', 'delivery', 'lunch'], hours: { weekday: '11:00 AM – 9:00 PM' }, rewardOffer: 'Double points at lunch', menuNote: 'Downtown menu coming soon.' },
  { id: 'events', name: 'Ambar India Events', address: 'By appointment', phone: '', services: ['catering', 'private-events'], hours: {}, rewardOffer: 'Earn points on catered events', menuNote: 'Catering and private-event menu.' },
];

export function loadLocations() {
  try { const saved = JSON.parse(localStorage.getItem(LOCATION_STORE)); return Array.isArray(saved) && saved.length ? saved : starterLocations; } catch { return starterLocations; }
}
export function saveLocations(locations) { localStorage.setItem(LOCATION_STORE, JSON.stringify(locations)); }
export function makeLocationId(name) { return `${name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '')}-${Date.now().toString().slice(-4)}`; }

const fromRow = (row) => ({ id: row.id, name: row.name, address: row.address, phone: row.phone, services: row.services || [], hours: row.hours || {}, rewardOffer: row.reward_offer || '', menuNote: row.menu_note || '' });
const toRow = (location) => ({ id: location.id, name: location.name, address: location.address || '', phone: location.phone || '', services: location.services || [], hours: location.hours || {}, reward_offer: location.rewardOffer || '', menu_note: location.menuNote || '', is_active: true });

export async function loadCloudLocations() {
  if (!supabase) return { locations: null, error: 'Supabase environment values are missing.' };
  const { data, error } = await supabase.from('locations').select('*').eq('is_active', true).order('name');
  return { locations: error || !data?.length ? null : data.map(fromRow), error: error?.message || null };
}

export async function saveCloudLocations(locations) {
  if (!supabase) return { error: 'Supabase environment values are missing.' };
  const { error } = await supabase.from('locations').upsert(locations.map(toRow));
  return { error: error?.message || null };
}
import { supabase } from './supabaseClient.js';
