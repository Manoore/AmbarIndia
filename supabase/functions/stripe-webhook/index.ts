import Stripe from 'https://esm.sh/stripe@17.5.0?target=deno';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') || '', { apiVersion: '2025-07-30.basil' });
const supabase = createClient(Deno.env.get('SUPABASE_URL') || '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '');

Deno.serve(async (request) => {
  const signature = request.headers.get('stripe-signature'); const payload = await request.text();
  let event; try { event = await stripe.webhooks.constructEventAsync(payload, signature || '', Deno.env.get('STRIPE_WEBHOOK_SECRET') || ''); } catch { return new Response('Invalid signature', { status: 400 }); }
  const object = event.data.object as any; const organizationId = object.metadata?.organization_id;
  if (organizationId && ['checkout.session.completed', 'customer.subscription.updated', 'customer.subscription.deleted', 'invoice.payment_failed'].includes(event.type)) {
    const status = event.type === 'invoice.payment_failed' ? 'past_due' : event.type === 'customer.subscription.deleted' ? 'suspended' : event.type === 'checkout.session.completed' ? 'active' : (object.status === 'trialing' ? 'trial' : 'active');
    await supabase.from('organizations').update({ status, stripe_subscription_id: object.subscription || object.id, current_period_end: object.current_period_end ? new Date(object.current_period_end * 1000).toISOString() : null }).eq('id', organizationId);
  }
  return new Response('ok');
});
