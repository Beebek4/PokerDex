// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin");
const colors = require("tailwindcss/colors");
const fs = require("fs");
const path = require("path");

module.exports = {
  content: ["./js/**/*.js", "../lib/*.ex", "../lib/**/*.*ex"],
  theme: {
    extend: {
      screens: {
        "3xl": "1800px",
        "4xl": "2100px",
        "5xl": "2400px",
        "6xl": "2700px",
        "7xl": "3000px",
      },
      colors: {
        gray: {
          50: "#FFFFFF",
          100: "#F6F5F7",
          200: "#E6E5EB",
          300: "#A7ADC6",
          400: "#8797AF",
          500: "#56667A",
          600: "#56667A",
          700: "#5F4B66",
          800: "#2C1320",
          900: "#2C1320",
          950: "#2C1320",
        },
        slate: {
          50: "#FFFFFF",
          100: "#F6F5F7",
          200: "#E6E5EB",
          300: "#A7ADC6",
          400: "#8797AF",
          500: "#56667A",
          600: "#56667A",
          700: "#5F4B66",
          800: "#2C1320",
          900: "#2C1320",
          950: "#2C1320",
        },
        indigo: {
          50: "#F7F5F8",
          100: "#EDE9F0",
          200: "#D9D2DE",
          300: "#A7ADC6",
          400: "#8797AF",
          500: "#5F4B66",
          600: "#5F4B66",
          700: "#2C1320",
          800: "#2C1320",
          900: "#2C1320",
          950: "#2C1320",
        },
        cyan: {
          50: "#F4F6F8",
          100: "#E8ECF1",
          200: "#CBD3DE",
          300: "#A7ADC6",
          400: "#8797AF",
          500: "#56667A",
          600: "#56667A",
          700: "#5F4B66",
          800: "#5F4B66",
          900: "#2C1320",
          950: "#2C1320",
        },
      },
      boxShadow: {
        "b-gray": "3px 3px 0px 0px #A7ADC6",
        "b-gray-pressed": "1px 1px 0px 0px #A7ADC6",
        "b-cyan": "3px 3px 0px 0px #A7ADC6",
        "b-cyan-pressed": "1px 1px 0px 0px #A7ADC6",
        "b-teal": `3px 3px 0px 0px ${colors.teal[300]}`,
        "b-teal-pressed": `1px 1px 0px 0px ${colors.teal[300]}`,
        "b-pink": `3px 3px 0px 0px ${colors.pink[300]}`,
        "b-pink-pressed": `1px 1px 0px 0px ${colors.pink[300]}`,
        "b-indigo": "3px 3px 0px 0px #A7ADC6",
        "b-indigo-pressed": "1px 1px 0px 0px #A7ADC6",
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/container-queries"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({ addVariant }) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({ addVariant }) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({ addVariant }) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),
    plugin(({ addVariant }) => addVariant("drag-item", [".drag-item&", ".drag-item &"])),
    plugin(({ addVariant }) => addVariant("drag-ghost", [".drag-ghost&", ".drag-ghost &"])),

    // Embeds Tabler Icons (https://tabler-icons.io/) into your app.css bundle
    // Credits: [Florian Arens](https://farens.me/blog/how-to-integrate-tabler-icons-into-your-phoenix-project)
    plugin(function ({ matchComponents, theme }) {
      const iconsDir = path.join(__dirname, "../deps/tabler_icons/icons");
      const values = {};

      const icons = [
        ["", "/outline"],
        ["-filled", "/filled"],
      ];

      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach((file) => {
          const name = path.basename(file, ".svg") + suffix;
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) };
        });
      });

      matchComponents(
        {
          tabler: ({ name, fullPath }) => {
            const content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, "")
              .replace(/width="[^"]*"/, "")
              .replace(/height="[^"]*"/, "")
              .replace('stroke-width="2"', 'stroke-width="1"');

            return {
              [`--tabler-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
              "-webkit-mask": `var(--tabler-${name})`,
              mask: `var(--tabler-${name})`,
              "mask-repeat": "no-repeat",
              "background-color": "currentColor",
              "vertical-align": "middle",
              display: "inline-block",
              width: theme("spacing.5"),
              height: theme("spacing.5"),
            };
          },
        },
        { values }
      );
    }),
  ],
};
