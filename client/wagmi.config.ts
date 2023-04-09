import { defineConfig } from "@wagmi/cli";
import { foundry, react } from "@wagmi/cli/plugins";

export default defineConfig({
  out: "src/contracts/generated.ts",
  plugins: [
    foundry({
      project: "../",
      exclude: [
        "ERC1967Proxy.sol/**",
        "Mock**.sol/**",
        "Lock.sol/**",
        "*.t.sol",
      ],
    }),
    react(),
  ],
});
