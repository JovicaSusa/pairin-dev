module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.css',
    './app/javascript/**/*.{js,jsx}',
    'config/initializers/simple_form.rb'
  ],
  theme: {
    extend: {
      colors: {
        // brand colors (used directly in layout/semantic contexts)
        orange: "#FF8B37",
        purple: "#7B5FF1",
        green: "#55D087",
        red: "#F1495F",
        // neobrutalism token colors (consumed by installed components)
        main: 'var(--main)',
        'main-foreground': 'var(--main-foreground)',
        background: 'var(--background)',
        'secondary-background': 'var(--secondary-background)',
        foreground: 'var(--foreground)',
        border: 'var(--border)',
        ring: 'var(--ring)',
        overlay: 'var(--overlay)',
      },
      fontFamily: {
        "sans": ["Cabin", "sans-serif"],
        "headline": ["Work Sans"],
        "display": ["Outfit", "sans-serif"]
      },
      fontWeight: {
        base: '500',
        heading: '700',
      },
      boxShadow: {
        shadow: 'var(--shadow)',
      },
      borderRadius: {
        base: '0.75rem',
      },
      translate: {
        boxShadowX: '4px',
        boxShadowY: '4px',
        reverseBoxShadowX: '-4px',
        reverseBoxShadowY: '-4px',
      },
      animation: {
        marquee: "marquee 120s linear infinite",
        marquee2: "marquee2 120s linear infinite",
        appearThenFade: "appearThenFade 5s linear"
      },
      keyframes: {
        marquee: {
          "0%": { transform: "translateX(0%)" },
          "100%": { transform: "translateX(-100%)" },
        },
        marquee2: {
          "0%": { transform: "translateX(100%)" },
          "100%": { transform: "translateX(0%)" },
        },
        appearThenFade: {
          "0%, 100%": { opacity: 0 },
          "5%, 60%": { opacity: 1 }
        }
      },
    },
  },
}
