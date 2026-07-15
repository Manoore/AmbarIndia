import React, { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './App.jsx';
import AdminDashboard from './AdminDashboard.jsx';
import MenuPage from './MenuPage.jsx';
import PlatformDashboard from './PlatformDashboard.jsx';
import { AdminQuickLogout, AdminToastHost } from './AdminChrome.jsx';
import '../styles.css';
import './AdminChrome.css';
import './AnalyticsDashboard.css';
import './CounterPOS.css';
import './PlatformOperations.css';
import './PlatformNavigation.css';
import { PlatformSectionLinks } from './PlatformOperations.jsx';

const rootElement = document.getElementById('root');
try {
  const isAdmin = window.location.pathname.startsWith('/admin');
  const isMenu = window.location.pathname.startsWith('/menu');
  const isSite = window.location.pathname.startsWith('/site/');
  const isPlatform = window.location.pathname.startsWith('/platform');
  const Screen = isPlatform ? PlatformDashboard : isAdmin ? AdminDashboard : isMenu ? MenuPage : isSite ? App : App;
  createRoot(rootElement).render(<StrictMode><Screen /><PlatformSectionLinks /><AdminQuickLogout /><AdminToastHost /></StrictMode>);
} catch (error) {
  console.error('Ambar application failed to start.', error);
  rootElement.innerHTML = '<main class="startup-message"><p>AMBAR INDIA</p><h1>We’re refreshing the experience.</h1><span>Please refresh this page in a moment.</span></main>';
}
