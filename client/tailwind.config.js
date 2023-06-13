/** @type {import("tailwindcss").Config} */
module.exports = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx}",
    "./src/components/**/*.{js,ts,jsx,tsx}",
    "./src/app/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      maxWidth: {
        90: "22.5rem",
      },
      maxHeight: {
        90: "22.5rem",
      },
      colors: {
        badge: "#242424",
        badgeText: "#A0A0A0",
        title: "#FFFFFF",
        subtitle: "#FFFFFF",
        paragraph: "#A4A4A4",
        primary: "#050005",
        secondary: "#050005",
        background: "#050005",
      },
      backgroundImage: {
        "gradient-radial": "radial-gradient(var(--tw-gradient-stops))",
        "gradient-conic":
          "conic-gradient(from 180deg at 50% 50%, var(--tw-gradient-stops))",
      },
      opacity: ["disabled"],
    },
  },
  plugins: [],
};
