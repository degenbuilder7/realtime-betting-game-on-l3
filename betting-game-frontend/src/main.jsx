import React from "react";
import ReactDOM from "react-dom/client";

//wallet import
import {
  getDefaultWallets,
  RainbowKitProvider,
  midnightTheme,
} from "@rainbow-me/rainbowkit";

import { configureChains, createClient, WagmiConfig } from "wagmi";
import {  sepolia} from "wagmi/chains";
import { publicProvider } from "wagmi/providers/public";

//routes import
import App from "./App";

//style import
import "@rainbow-me/rainbowkit/styles.css";
import "./styles/site.css";

const gamingl3chain = {
  id: 60385,
  name: 'gamingonl3-OP-MODE-CELESTIA',
  nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
  rpcUrls: {
    default: { http: ['https://rpc-useful-aquamarine-rhinoceros-dufw1ydgcn.t.conduit.xyz'] },
  },
  blockExplorers: {
    default: { name: 'Blockscout', url: 'https://explorerl2new-useful-aquamarine-rhinoceros-dufw1ydgcn.t.conduit.xyz' },
  },
};

//wagmi
const { chains, provider } = configureChains(
  [gamingl3chain],
  [publicProvider()]
);

const { connectors } = getDefaultWallets({
  appName: "Betting on the wheels of fortune",
  chains,
});

const wagmiClient = createClient({
  autoConnect: true,
  connectors,
  provider,
});

ReactDOM.createRoot(document.getElementById("root")).render(
  <WagmiConfig client={wagmiClient}>
    <RainbowKitProvider coolMode theme={midnightTheme()} chains={chains}>
      <App />
    </RainbowKitProvider>
  </WagmiConfig>
);
