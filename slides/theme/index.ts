/**
 * Slidev Theme: Coral Bold
 * A vibrant theme with coral colors and bold typography
 */

import themeStyles from './styles/index'

export default {
  // Theme configuration
  colorSchema: 'auto', // auto, light, dark

  // Export styles
  setup: () => {
    // Inject theme styles
    if (typeof document !== 'undefined') {
      const style = document.createElement('style')
      style.textContent = themeStyles
      document.head.appendChild(style)
    }
  }
}
