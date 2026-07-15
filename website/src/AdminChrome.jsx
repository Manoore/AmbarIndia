import React, { useEffect, useState } from 'react';
import { supabase } from './supabaseClient.js';

const EVENT_NAME = 'ambar-admin-toast';

export function notifyAdmin(message) {
  if (typeof window !== 'undefined') {
    window.dispatchEvent(new CustomEvent(EVENT_NAME, { detail: message }));
  }
}

export function AdminToastHost() {
  const [message, setMessage] = useState('');
  useEffect(() => {
    const show = (event) => {
      setMessage(event.detail || '');
      window.clearTimeout(show.timer);
      show.timer = window.setTimeout(() => setMessage(''), 4200);
    };
    window.addEventListener(EVENT_NAME, show);
    return () => window.removeEventListener(EVENT_NAME, show);
  }, []);
  if (!message) return null;
  return <div className="admin-in-app-notice" role="status" aria-live="polite"><span>{message}</span><button onClick={() => setMessage('')} aria-label="Dismiss message">×</button></div>;
}

export function AdminQuickLogout() {
  if (typeof window === 'undefined' || !window.location.pathname.startsWith('/admin')) return null;
  return <button className="admin-top-logout" onClick={() => supabase.auth.signOut()}>Sign out</button>;
}
