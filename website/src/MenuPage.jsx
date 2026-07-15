import React, { useEffect, useState } from 'react';
import MenuCatalogue from './MenuCatalogue.jsx';
import CheckoutDrawer from './CheckoutDrawer.jsx';
import { loadCloudLocations, loadLocations } from './locationStore.js';

function Brand() { return <a className="brand" href="/">AMBAR <span>INDIA</span><small>RESTAURANT</small></a>; }

export default function MenuPage() {
  const [cart, setCart] = useState([]);
  const [checkout, setCheckout] = useState(false);
  const [locations, setLocations] = useState(() => loadLocations());
  const [selectedId, setSelectedId] = useState(() => localStorage.getItem('ambar-selected-location') || loadLocations()[0].id);
  const selected = locations.find((location) => location.id === selectedId) || locations[0];
  const addToCart = (item) => setCart((previous) => { const found = previous.find((line) => line.name === item.name); return found ? previous.map((line) => line.name === item.name ? { ...line, quantity: line.quantity + 1 } : line) : [...previous, { ...item, quantity: 1 }]; });
  const removeFromCart = (name) => setCart((previous) => previous.filter((item) => item.name !== name));
  useEffect(() => { loadCloudLocations().then(({ locations: cloud }) => { if (cloud) setLocations(cloud); }); }, []);

  return <><div className="announcement">Order directly from Ambar India · Save on fees · Earn rewards</div><header className="site-header menu-page-header"><Brand /><nav><a href="/#story">Our story</a><a className="active" href="/menu">Menu</a><a href="/#catering">Catering</a><a href="/#visit">Visit us</a></nav><button className="outline-button" onClick={() => setCheckout(true)}>Your order ({cart.reduce((sum, item) => sum + item.quantity, 0)}) <b>→</b></button></header><main className="menu-page-main"><div className="menu-location-bar"><span>Ordering from <b>{selected.name}</b></span><select value={selectedId} onChange={(event) => { localStorage.setItem('ambar-selected-location', event.target.value); setSelectedId(event.target.value); }}>{locations.map((location) => <option value={location.id} key={location.id}>{location.name}</option>)}</select></div><MenuCatalogue onAdd={addToCart} location={selected} /></main><footer><Brand /><div><a href="/">Home</a><a href="/#catering">Catering</a><a href="/#visit">Contact</a></div><p>© 2026 Ambar India Restaurant</p></footer>{checkout && <CheckoutDrawer location={selected} cart={cart} onClose={() => setCheckout(false)} onClear={() => setCart([])} onRemove={removeFromCart} />}</>;
}
