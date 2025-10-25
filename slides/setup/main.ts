/**
 * Setup file for Coral Bold theme
 * This file is automatically loaded by Slidev
 */

import { defineAppSetup } from '@slidev/types'

export default defineAppSetup(({ app, router }) => {
  // Load theme styles
  const themeStyles = `
/* ============================================
   Coral Bold Theme - Color Palette
   ============================================ */

:root {
  /* Primary Coral Colors */
  --coral-primary: #FF7F50;
  --coral-light: #FFB499;
  --coral-dark: #E85D3A;
  --coral-darker: #CC4522;

  /* Accent Colors */
  --accent-teal: #20B2AA;
  --accent-navy: #1E3A5F;
  --accent-gold: #FFD700;

  /* Neutral Colors */
  --neutral-100: #F8F9FA;
  --neutral-200: #E9ECEF;
  --neutral-300: #DEE2E6;
  --neutral-700: #495057;
  --neutral-800: #343A40;
  --neutral-900: #212529;

  /* Theme Variables */
  --slidev-theme-primary: var(--coral-primary);
  --slidev-theme-accents-teal: var(--accent-teal);
  --slidev-theme-accents-navy: var(--accent-navy);
}

/* ============================================
   Dark Mode Overrides
   ============================================ */

html.dark {
  --neutral-100: #212529;
  --neutral-200: #343A40;
  --neutral-300: #495057;
  --neutral-700: #DEE2E6;
  --neutral-800: #E9ECEF;
  --neutral-900: #F8F9FA;
}

/* ============================================
   Typography - Bold Style
   ============================================ */

.slidev-layout {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
  color: var(--neutral-900);
}

html.dark .slidev-layout {
  color: var(--neutral-900);
}

/* Headings with Bold Style */
.slidev-layout h1 {
  font-size: 3.5rem;
  font-weight: 900;
  line-height: 1.1;
  color: var(--coral-primary);
  margin-bottom: 1.5rem;
  letter-spacing: -0.02em;
}

.slidev-layout h2 {
  font-size: 2.5rem;
  font-weight: 800;
  line-height: 1.2;
  color: var(--coral-dark);
  margin-bottom: 1.25rem;
  letter-spacing: -0.01em;
}

.slidev-layout h3 {
  font-size: 1.875rem;
  font-weight: 700;
  line-height: 1.3;
  color: var(--accent-navy);
  margin-bottom: 1rem;
}

.slidev-layout h4 {
  font-size: 1.5rem;
  font-weight: 700;
  line-height: 1.4;
  color: var(--neutral-800);
  margin-bottom: 0.875rem;
}

.slidev-layout p {
  font-size: 1.125rem;
  line-height: 1.75;
  margin-bottom: 1rem;
  font-weight: 500;
}

.slidev-layout strong,
.slidev-layout b {
  font-weight: 800;
  color: var(--coral-dark);
}

.slidev-layout em {
  font-style: italic;
  color: var(--accent-teal);
}

/* ============================================
   Links and Interactive Elements
   ============================================ */

.slidev-layout a {
  color: var(--coral-primary);
  text-decoration: none;
  font-weight: 600;
  border-bottom: 2px solid transparent;
  transition: all 0.3s ease;
}

.slidev-layout a:hover {
  color: var(--coral-dark);
  border-bottom-color: var(--coral-primary);
}

/* ============================================
   Lists with Coral Accents
   ============================================ */

.slidev-layout ul,
.slidev-layout ol {
  margin-left: 1.5rem;
  margin-bottom: 1rem;
}

.slidev-layout li {
  margin-bottom: 0.5rem;
  padding-left: 0.5rem;
  font-weight: 500;
}

.slidev-layout ul > li::marker {
  color: var(--coral-primary);
  font-weight: 900;
  font-size: 1.25em;
}

.slidev-layout ol > li::marker {
  color: var(--coral-primary);
  font-weight: 800;
}

/* ============================================
   Code Blocks
   ============================================ */

.slidev-layout code {
  background: var(--neutral-200);
  padding: 0.2em 0.4em;
  border-radius: 0.25rem;
  font-size: 0.9em;
  font-weight: 600;
  color: var(--accent-navy);
  font-family: 'JetBrains Mono', 'Fira Code', Consolas, monospace;
}

.slidev-layout pre {
  background: var(--neutral-200);
  padding: 1.5rem;
  border-radius: 0.5rem;
  overflow-x: auto;
  margin: 1rem 0;
  border-left: 4px solid var(--coral-primary);
}

.slidev-layout pre code {
  background: transparent;
  padding: 0;
  font-size: 0.95rem;
  font-weight: 500;
}

/* ============================================
   Blockquotes
   ============================================ */

.slidev-layout blockquote {
  border-left: 4px solid var(--coral-primary);
  padding-left: 1.5rem;
  margin: 1.5rem 0;
  font-style: italic;
  font-weight: 600;
  color: var(--neutral-700);
  background: var(--neutral-200);
  padding: 1rem 1.5rem;
  border-radius: 0 0.5rem 0.5rem 0;
}

/* ============================================
   Buttons and Interactive Elements
   ============================================ */

.slidev-layout button,
.slidev-layout .button {
  background: var(--coral-primary);
  color: white;
  font-weight: 700;
  padding: 0.75rem 1.5rem;
  border-radius: 0.5rem;
  border: none;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 1rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.slidev-layout button:hover,
.slidev-layout .button:hover {
  background: var(--coral-dark);
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(255, 127, 80, 0.4);
}

/* ============================================
   Tables
   ============================================ */

.slidev-layout table {
  width: 100%;
  border-collapse: collapse;
  margin: 1.5rem 0;
  font-weight: 500;
}

.slidev-layout th {
  background: var(--coral-primary);
  color: white;
  padding: 0.75rem 1rem;
  text-align: left;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  font-size: 0.9rem;
}

.slidev-layout td {
  padding: 0.75rem 1rem;
  border-bottom: 1px solid var(--neutral-300);
}

.slidev-layout tr:hover {
  background: var(--neutral-200);
}

/* ============================================
   Special Classes
   ============================================ */

.coral-accent {
  color: var(--coral-primary) !important;
  font-weight: 700;
}

.bold-text {
  font-weight: 800;
}

.gradient-text {
  background: linear-gradient(135deg, var(--coral-primary), var(--accent-teal));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  font-weight: 900;
}

.coral-bg {
  background: var(--coral-primary);
  color: white;
  padding: 2rem;
  border-radius: 0.5rem;
}

.teal-bg {
  background: var(--accent-teal);
  color: white;
  padding: 2rem;
  border-radius: 0.5rem;
}

/* ============================================
   Slide Numbers and Navigation
   ============================================ */

.slidev-page-indicator {
  color: var(--coral-primary);
  font-weight: 700;
}

/* ============================================
   Transitions and Animations
   ============================================ */

.slidev-vclick-target {
  transition: all 0.3s ease;
}

.slidev-vclick-hidden {
  opacity: 0;
  transform: translateY(10px);
}

/* ============================================
   Custom Slide Styling
   ============================================ */

.slidev-layout .slide-title {
  font-size: 3rem;
  font-weight: 900;
  background: linear-gradient(135deg, var(--coral-primary), var(--coral-darker));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  margin-bottom: 2rem;
}
  `

  // Inject styles
  if (typeof document !== 'undefined') {
    const style = document.createElement('style')
    style.id = 'coral-bold-theme'
    style.textContent = themeStyles
    document.head.appendChild(style)
  }

  // You can add more setup logic here
  // For example, custom components, plugins, etc.
})
