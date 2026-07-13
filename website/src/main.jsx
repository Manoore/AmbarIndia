import React, { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './App.jsx';
import AdminDashboard from './AdminDashboard.jsx';
import '../styles.css';

const rootElement = document.getElementById('root');
try {
  const isAdmin = window.location.pathname.startsWith('/admin');
  const Screen = isAdmin ? AdminDashboard : App;
  createRoot(rootElement).render(<StrictMode><Screen /></StrictMode>);
} catch (error) {
  console.error('Ambar application failed to start.', error);
  rootElement.innerHTML = '<main class="startup-message"><p>AMBAR INDIA</p><h1>We’re refreshing the experience.</h1><span>Please refresh this page in a moment.</span></main>';
}
