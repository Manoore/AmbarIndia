import { supabase } from './supabaseClient.js';

export async function listLocationMenuItems(locationId) {
  if (!supabase || !locationId) return { items: [], error: null };
  const { data, error } = await supabase.from('menu_items').select('id,location_id,category,name,description,price,image_url,available,sort_order').eq('location_id', locationId).order('sort_order').order('name');
  return { items: data || [], error: error?.message || null };
}

export async function createLocationMenuItem(item) {
  if (!supabase) return { item: null, error: 'Menu service is unavailable.' };
  const { data, error } = await supabase.from('menu_items').insert(item).select().single();
  return { item: data, error: error?.message || null };
}

export async function updateLocationMenuItem(id, patch) {
  if (!supabase) return { error: 'Menu service is unavailable.' };
  const { error } = await supabase.from('menu_items').update(patch).eq('id', id);
  return { error: error?.message || null };
}
