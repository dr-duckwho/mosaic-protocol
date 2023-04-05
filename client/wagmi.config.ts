import { defineConfig } from "@wagmi/cli";
import { foundry, react } from "@wagmi/cli/plugins";

export default defineConfig({
  out: "contract/generated.ts",
  plugins: [
    foundry({
      project: "../",
      exclude: ["ERC1967Proxy.sol/**", "Mock**.sol/**"],
    }),
    react(),
  ],
});
