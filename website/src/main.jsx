import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import '../styles.css';

const rootElement = document.getElementById('root');
rootElement.innerHTML = '<main class="startup-message"><p>AMBAR INDIA</p><h1>Preparing your table…</h1><span>Loading the Ambar experience.</span></main>';

try {
  const isAdmin = window.location.pathname.startsWith('/admin');
  const module = await import(isAdmin ? './AdminDashboard.jsx' : './App.jsx');
  const Screen = module.default;
  createRoot(rootElement).render(<StrictMode><Screen /></StrictMode>);
} catch (error) {
  console.error('Ambar application failed to start.', error);
  rootElement.innerHTML = '<main class="startup-message"><p>AMBAR INDIA</p><h1>We’re refreshing the experience.</h1><span>Please refresh this page in a moment.</span></main>';
}
