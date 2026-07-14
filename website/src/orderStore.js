import { supabase } from './supabaseClient.js';

const orderReference = () => `AI-${new Date().toISOString().slice(2, 10).replaceAll('-', '')}-${Math.floor(1000 + Math.random() * 9000)}`;
const accessToken = () => crypto.randomUUID();

export async function createOrder({ locationId, orderType, guestName, guestPhone, tableNumber, paymentMethod = 'pay-at-counter', cart, kitchenNote = '' }) {
  const subtotal = cart.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const reference = orderReference();
  const token = accessToken();
  const order = { location_id: locationId, order_type: orderType, order_source: 'online', guest_name: guestName || null, guest_phone: guestPhone || null, table_number: tableNumber || null, subtotal, total: subtotal, payment_method: paymentMethod, payment_status: 'pending', kitchen_note: kitchenNote, order_reference: reference, access_token: token };
  if (!supabase) return { error: 'Ordering is temporarily unavailable.' };
  const { error: orderError } = await supabase.from('orders').insert(order);
  if (orderError) return { error: orderError.message };
  const { data: created, error: trackError } = await supabase.rpc('track_order', { p_order_reference: reference, p_access_token: token });
  return { order: { ...order, id: created?.[0]?.id, accessToken: token }, error: null, trackingError: trackError?.message || null };
}

export async function createStaffOrder(input) {
  if (!supabase) return { error: 'Ordering is temporarily unavailable.' };
  const subtotal = input.cart.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const reference = orderReference(); const token = accessToken();
  const { data, error } = await supabase.from('orders').insert({ location_id: input.locationId, order_type: input.orderType, order_source: 'walk-in', guest_name: input.guestName || null, guest_phone: input.guestPhone || null, table_number: input.tableNumber || null, subtotal, total: subtotal, payment_method: input.paymentMethod || 'card-terminal', payment_status: input.paymentStatus || 'paid', amount_tendered: input.amountTendered || null, kitchen_note: input.kitchenNote || '', order_reference: reference, access_token: token, estimated_ready_at: new Date(Date.now() + 25 * 60000).toISOString() }).select().single();
  if (error) return { error: error.message };
  const { error: itemsError } = await supabase.from('order_items').insert(input.cart.map((item) => ({ order_id: data.id, name: item.name, unit_price: item.price, quantity: item.quantity })));
  return { order: data, error: itemsError?.message || null };
}

export async function listManagerOrders() {
  if (!supabase) return { orders: [], error: 'Orders are temporarily unavailable.' };
  const { data, error } = await supabase.from('orders').select('id,order_reference,location_id,order_type,order_source,status,guest_name,guest_phone,table_number,total,payment_method,payment_status,amount_tendered,kitchen_note,estimated_ready_at,created_at,order_items(name,quantity,unit_price)').order('created_at', { ascending: false }).limit(200);
  return { orders: data || [], error: error?.message || null };
}
export async function updateOrderStatus(id, status, note = '') { if (!supabase) return { error: 'Orders are temporarily unavailable.' }; const patch = { status, kitchen_note: note }; if (status === 'preparing') patch.estimated_ready_at = new Date(Date.now() + 25 * 60000).toISOString(); const { error } = await supabase.from('orders').update(patch).eq('id', id); return { error: error?.message || null }; }
export async function updateOrderPayment(id, paymentMethod, amountTendered, paymentStatus = 'paid') { if (!supabase) return { error: 'Payments are temporarily unavailable.' }; const { error } = await supabase.from('orders').update({ payment_method: paymentMethod, amount_tendered: amountTendered || null, payment_status: paymentStatus }).eq('id', id); return { error: error?.message || null }; }
export async function trackOrder(reference, token) { if (!supabase) return { order: null, error: 'Order tracking is temporarily unavailable.' }; const { data, error } = await supabase.rpc('track_order', { p_order_reference: reference, p_access_token: token }); return { order: data?.[0] || null, error: error?.message || null }; }
export const orderStages = ['new', 'preparing', 'ready', 'completed'];
