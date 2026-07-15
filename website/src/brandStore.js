import { supabase } from './supabaseClient.js';

export const defaultBrand = { name: 'Ambar India', tagline: "Northern Indian cuisine · warmly served", logo_url: '', primary_color: '#5b1723', accent_color: '#d9ff75' };

export async function loadBrandConfig(slug = 'ambar-india') {
  if (!supabase) return defaultBrand;
  const { data, error } = await supabase.from('organizations').select('name,tagline,logo_url,primary_color,accent_color').eq('slug', slug).maybeSingle();
  return error || !data ? defaultBrand : { ...defaultBrand, ...data };
}
