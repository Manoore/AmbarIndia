import React, { useEffect, useMemo, useState } from 'react';

const fallback = [{ category: 'Appetizers', items: [['Vegetable Samosa', 9.89, 'Two crisp pastries with potatoes and green peas'], ['Paneer Pakora', 12.99, 'Lightly spiced and batter fried']] }];
const cloudPhotos = {
  snack: ['photo-1601050690117-94f5f6fa8bd7', 'photo-1601050690597-df0568f70950', 'photo-1626132647523-66f5bf380027', 'photo-1589302168068-964664d93dc0'],
  grill: ['photo-1599487488170-d11ec9c172f0', 'photo-1567188040759-fb8a883dc6d8', 'photo-1628294895950-9805252327bc', 'photo-1596797038530-2c107229654b'],
  curry: ['photo-1585937421612-70a008356fbe', 'photo-1589647363585-f4a7d3877b10', 'photo-1603894584373-5ac82b2ae398', 'photo-1631452180519-c014fe946bc7'],
  rice: ['photo-1642821373181-696a54913e93', 'photo-1596450514735-111a2fe02935', 'photo-1563379926898-05f4575a45d8', 'photo-1574653853027-5382a3d23a15'],
  bread: ['photo-1610057099431-d73a1c9d2f2f', 'photo-1603894584373-5ac82b2ae398', 'photo-1601050690117-94f5f6fa8bd7', 'photo-1565557623262-b51c2513a641'],
  sweet: ['photo-1601303516534-b1e7d8b2d4cf', 'photo-1563805042-7684c019e1cb', 'photo-1565958011703-44f9829ba187', 'photo-1571877227200-a0d98ea607e9'],
  drink: ['photo-1551024709-8f23befc6f87', 'photo-1544145945-f90425340c7e', 'photo-1553530666-ba11a7da3888', 'photo-1513558161293-cdaf765ed2fd']
};
const photoUrl = (id) => `https://images.unsplash.com/${id}?auto=format&fit=crop&w=900&q=82`;
const photoGroup = (category, name) => {
  const text = `${category} ${name}`.toLowerCase();
  if (/dessert|sweet|gulab|kheer|kulfi|ice cream|halwa|rasmalai/.test(text)) return 'sweet';
  if (/drink|beverage|lassi|tea|coffee|soda|juice/.test(text)) return 'drink';
  if (/bread|naan|roti|paratha|kulcha/.test(text)) return 'bread';
  if (/rice|biryani|pulao/.test(text)) return 'rice';
  if (/tandoori|kebab|kabob|grill|chicken|lamb|goat|fish|shrimp/.test(text)) return 'grill';
  if (/samosa|tikki|chaat|pakora|appetizer|salad|soup/.test(text)) return 'snack';
  return 'curry';
};
const photoFor = (category, name = '', index = 0) => {
  const group = photoGroup(category, name);
  const photos = cloudPhotos[group];
  const seed = [...`${category}-${name}`].reduce((total, char) => total + char.charCodeAt(0), index);
  return photoUrl(photos[seed % photos.length]);
};
const priceNumber = (price) => Number(String(price).replace(/[^0-9.]/g, '')) || 0;
const priceLabel = (price) => typeof price === 'number' ? `$${price.toFixed(2)}` : `$${price}`;

export default function MenuCatalogue({ onAdd }) {
  const [categories, setCategories] = useState(fallback);
  const [cat, setCat] = useState('Appetizers');

  useEffect(() => {
    fetch('/data/ambar-menu.json').then((response) => response.ok ? response.json() : Promise.reject()).then((data) => {
      if (data.categories?.length) { setCategories(data.categories); setCat(data.categories[0].category); }
    }).catch(() => {});
  }, []);

  const active = useMemo(() => categories.find((item) => item.category === cat) || categories[0], [categories, cat]);
  const heroPhoto = photoFor(active.category, active.category);

  return <section id="full-menu" className="catalogue">
    <div key={active.category} className="catalogue-hero" style={{ backgroundImage: `linear-gradient(90deg,#270b11bd,#270b1120),url('${heroPhoto}')` }}><div><p className="eyebrow">Ambar India menu</p><h2>Made fresh.<br />Made to share.</h2><span>{active.hours || "Chef's picks, made for your table"}</span><small>Choose a dish, add it to your order, and make it yours.</small></div><b className="catalogue-current">{active.category.replace(/^Lunch /, '')}</b></div>
    <div className="catalogue-body">
      <aside className="catalogue-tabs" aria-label="Menu categories">{categories.map((item) => <button className={cat === item.category ? 'active' : ''} onClick={() => setCat(item.category)} key={item.category}>{item.category.replace(/^Lunch /, '')}</button>)}</aside>
      <div className="catalogue-items" key={active.category}>
        <div className="menu-category-note">{active.note && <span>{active.note}</span>}<b>{active.items.length} items</b></div>
        <div className="catalogue-grid">{active.items.map((item, index) => { const name = item.name || item[0]; const price = item.price ?? item[1]; const description = item.description || item[2]; const photo = photoFor(active.category, name, index); return <article className="menu-card" key={name}><div className="menu-card-photo" style={{ backgroundImage: `url('${photo}')` }} /><b>{name}</b><span>{priceLabel(price)}</span>{description && <p>{description}</p>}<button onClick={() => onAdd?.({ name, price: priceNumber(price) })}>Add to order +</button></article>; })}</div>
        <small>Availability is confirmed when an order is placed.</small>
      </div>
    </div>
  </section>;
}
