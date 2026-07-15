import Stripe from 'https://esm.sh/stripe@17.5.0?target=deno';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') || '', { apiVersion: '2025-07-30.basil' });
const supabase = createClient(Deno.env.get('SUPABASE_URL') || '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '');

Deno.serve(async (request) => {
  if (request.method !== 'POST') return new Response('Method not allowed', { status: 405 });
  const auth = request.headers.get('Authorization') || '';
  const token = auth.replace('Bearer ', '');
  const { data: user } = await supabase.auth.getUser(token);
  if (!user.user) return Response.json({ error: 'Unauthorized' }, { status: 401 });
  const { data: admin } = await supabase.from('platform_admins').select('user_id').eq('user_id', user.user.id).maybeSingle();
  if (!admin) return Response.json({ error: 'Platform access required' }, { status: 403 });
  const { organizationId, priceId, returnUrl } = await request.json();
  const { data: organization } = await supabase.from('organizations').select('*').eq('id', organizationId).single();
  if (!organization) return Response.json({ error: 'Merchant not found' }, { status: 404 });
  const customer = organization.stripe_customer_id ? { id: organization.stripe_customer_id } : await stripe.customers.create({ name: organization.name, metadata: { organization_id: organization.id } });
  if (!organization.stripe_customer_id) await supabase.from('organizations').update({ stripe_customer_id: customer.id }).eq('id', organization.id);
  const session = await stripe.checkout.sessions.create({ mode: 'subscription', customer: customer.id, line_items: [{ price: priceId, quantity: 1 }], success_url: `${returnUrl}?billing=success`, cancel_url: `${returnUrl}?billing=cancelled`, metadata: { organization_id: organization.id } });
  return Response.json({ url: session.url });
});
