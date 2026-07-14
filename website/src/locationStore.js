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
