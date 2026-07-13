import http from 'node:http';

const restaurant = {
  id: 'ambar-india',
  name: 'Ambar India',
  locations: [
    { id: 'clifton', name: 'Ambar India Clifton', address: '350 Ludlow Ave, Cincinnati, OH 45220', phone: '513-281-7000', services: ['dine-in', 'pickup', 'delivery', 'catering'], hours: { sunday: '10:30 AM–9:30 PM', weekday: '10:30 AM–10:00 PM', saturday: '10:30 AM–10:00 PM' } },
    { id: 'downtown', name: 'Ambar India Downtown', address: 'To be configured', phone: '', services: ['pickup', 'delivery', 'lunch'], hours: {} },
    { id: 'events', name: 'Ambar India Events', address: 'To be configured', phone: '', services: ['catering', 'private-events'], hours: {} },
    { id: 'north', name: 'Ambar India North', address: 'To be configured', phone: '', services: ['dine-in', 'pickup'], hours: {} },
    { id: 'west', name: 'Ambar India West', address: 'To be configured', phone: '', services: ['pickup', 'delivery'], hours: {} },
  ],
};

const menu = [
  { id: 'chicken-tikka-masala', name: 'Chicken Tikka Masala', price: 22.99, category: 'Chicken', vegetarian: false },
  { id: 'saag-paneer', name: 'Saag Paneer', price: 22.99, category: 'Vegetarian', vegetarian: true },
  { id: 'garlic-naan', name: 'Garlic Naan', price: 7.99, category: 'Breads', vegetarian: true },
  { id: 'vegetable-samosa', name: 'Vegetable Samosa', price: 9.89, category: 'Appetizers', vegetarian: true },
];
const orders = [];

function json(response, status, payload) {
  response.writeHead(status, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' });
  response.end(JSON.stringify(payload));
}
async function body(request) {
  let content = '';
  for await (const chunk of request) content += chunk;
  return content ? JSON.parse(content) : {};
}

http.createServer(async (request, response) => {
  if (request.method === 'OPTIONS') return json(response, 204, {});
  const url = new URL(request.url, 'http://localhost');
  if (request.method === 'GET' && url.pathname === '/api/health') return json(response, 200, { ok: true });
  if (request.method === 'GET' && url.pathname === '/api/restaurants/ambar-india') return json(response, 200, restaurant);
  if (request.method === 'GET' && url.pathname === '/api/locations') return json(response, 200, restaurant.locations);
  if (request.method === 'GET' && url.pathname.startsWith('/api/locations/')) {
    const id = url.pathname.split('/').at(-1);
    const location = restaurant.locations.find((item) => item.id === id);
    return location ? json(response, 200, { ...location, menu }) : json(response, 404, { error: 'Location not found' });
  }
  if (request.method === 'POST' && url.pathname === '/api/orders') {
    const order = { id: `ORD-${Date.now()}`, status: 'received', createdAt: new Date().toISOString(), ...(await body(request)) };
    if (!order.locationId || !Array.isArray(order.items) || order.items.length === 0) return json(response, 400, { error: 'locationId and at least one item are required' });
    orders.push(order);
    return json(response, 201, order);
  }
  if (request.method === 'GET' && url.pathname === '/api/orders') return json(response, 200, orders);
  return json(response, 404, { error: 'Route not found' });
}).listen(3001, () => console.log('Ambar API running on http://localhost:3001'));
