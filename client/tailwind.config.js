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
        badge: "#3E2042",
        badgeText: "#A288BD",
        title: "#CFA4FF",
        subtitle: "#E5D1F9",
        paragraph: "#A288BD",
        primary: "#B97FFA",
        secondary: "#331235",
        background: "#230022",
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
