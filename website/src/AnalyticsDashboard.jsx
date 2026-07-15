import React, { useMemo, useState } from 'react';

const money = (value) => `$${Number(value || 0).toFixed(2)}`;
const dateKey = (value) => value ? new Date(value).toISOString().slice(0, 10) : '';

export default function AnalyticsDashboard({ orders = [], locations = [] }) {
  const [location, setLocation] = useState('all');
  const [source, setSource] = useState('all');
  const [status, setStatus] = useState('all');
  const [period, setPeriod] = useState('30');
  const today = new Date();
  const startDate = period === 'all' ? '' : new Date(today.getTime() - Number(period) * 86400000).toISOString().slice(0, 10);
  const filtered = useMemo(() => orders.filter((order) => {
    const created = dateKey(order.created_at);
    return (location === 'all' || order.location_id === location) && (source === 'all' || order.order_source === source) && (status === 'all' || order.status === status) && (!startDate || !created || created >= startDate);
  }), [orders, location, source, status, startDate]);
  const paid = filtered.filter((order) => order.payment_status === 'paid');
  const sales = paid.reduce((sum, order) => sum + Number(order.total || 0), 0);
  const pendingPayments = filtered.filter((order) => order.payment_status !== 'paid').reduce((sum, order) => sum + Number(order.total || 0), 0);
  const online = filtered.filter((order) => order.order_source === 'online').length;
  const walkin = filtered.filter((order) => ['walk-in', 'walkin', 'pos'].includes(order.order_source)).length;
  const cooking = filtered.filter((order) => order.status === 'preparing' || order.status === 'new').length;
  const byLocation = locations.map((item) => { const rows = filtered.filter((order) => order.location_id === item.id); return { name: item.name.replace('Ambar India ', ''), count: rows.length, sales: rows.filter((order) => order.payment_status === 'paid').reduce((sum, order) => sum + Number(order.total || 0), 0) }; });
  const max = Math.max(1, ...byLocation.map((item) => item.sales));
  return <section className="analytics"><header className="analytics-head"><div><p className="eyebrow">All-location intelligence</p><h2>Financials, orders and service pulse.</h2><p>Compare every restaurant, channel, and order stage from one view.</p></div><div className="analytics-filters"><label>Location<select value={location} onChange={(event) => setLocation(event.target.value)}><option value="all">All locations</option>{locations.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}</select></label><label>Period<select value={period} onChange={(event) => setPeriod(event.target.value)}><option value="7">Last 7 days</option><option value="30">Last 30 days</option><option value="90">Last 90 days</option><option value="all">All time</option></select></label><label>Channel<select value={source} onChange={(event) => setSource(event.target.value)}><option value="all">All channels</option><option value="online">Online</option><option value="walk-in">Walk-in / POS</option><option value="phone">Phone</option></select></label><label>Status<select value={status} onChange={(event) => setStatus(event.target.value)}><option value="all">All statuses</option><option value="new">New</option><option value="preparing">Cooking</option><option value="ready">Ready</option><option value="completed">Completed</option></select></label></div></header><div className="analytics-stats"><Stat label="Paid sales" value={money(sales)} note={`${paid.length} paid orders`} /><Stat label="Orders" value={filtered.length} note={`${online} online · ${walkin} walk-in`} /><Stat label="Unpaid value" value={money(pendingPayments)} note="Pending payment collection" /><Stat label="Kitchen now" value={cooking} note="New or cooking" /></div><div className="analytics-grid"><section className="analytics-card"><h3>Sales by location</h3>{byLocation.map((item) => <div className="bar-row" key={item.name}><span>{item.name}</span><div><i style={{ width: `${(item.sales / max) * 100}%` }} /></div><b>{money(item.sales)}</b><small>{item.count} orders</small></div>)}</section><section className="analytics-card"><h3>Order channels</h3><Payment label="Online" count={online} total={filtered.length} /><Payment label="Walk-in / POS" count={walkin} total={filtered.length} /><Payment label="Phone" count={filtered.filter((order) => order.order_source === 'phone').length} total={filtered.length} /><h3 className="analytics-subhead">Order stages</h3><div className="stage-list">{['new','preparing','ready','completed'].map((stage) => <span key={stage}><b>{filtered.filter((order) => order.status === stage).length}</b>{stage === 'preparing' ? 'Cooking' : stage}</span>)}</div></section></div></section>;
}
function Stat({ label, value, note }) { return <article><span>{label}</span><strong>{value}</strong><small>{note}</small></article>; }
function Payment({ label, count, total }) { return <p className="payment-row"><span>{label}</span><b>{count}</b><i><em style={{ width: `${total ? (count / total) * 100 : 0}%` }} /></i></p>; }
