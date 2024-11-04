module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js',
    'config/initializers/simple_form.rb'
  ],
  theme: {
    extend: {
      fontFamily: {
        "sans": ["Cabin", "sans-serif"],
        "handwritten": ["Yellowtail"],
        "headline": ["Work Sans"]
      },
      animation: {
        marquee: "marquee 120s linear infinite",
        appearThenFade: "appearThenFade 5s linear"
      },
      keyframes: {
        marquee: {
          "0%": { transform: "translateX(0%)" },
          "100%": { transform: "translateX(-100%)" },
        },
        appearThenFade: {
          "0%, 100%": { opacity: 0 },
          "5%, 60%": { opacity: 1 }
        }
      },
    },
  },
}
