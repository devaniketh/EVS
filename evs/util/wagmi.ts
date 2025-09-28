/* src/wagmi.ts */ 
'use client';

import { connectorsForWallets } from '@rainbow-me/rainbowkit';
import { createConfig, http } from 'wagmi';
import { mainnet, flowMainnet } from 'viem/chains';
import { flowWallet } from './flowWallet';

/*
We can leave this as is for the tutorial but it should be
replaced with your own project ID for production use.
*/
const projectId = 'YOUR_PROJECT_ID'; 

const connectors = connectorsForWallets(
  [
    {
      groupName: 'Recommended',
      wallets: [flowWallet]
    },
  ],
  {
    appName: 'RainbowKit App',
    projectId,
  }
);

export const config = createConfig({
  connectors,
  chains: [flowMainnet, mainnet],
  ssr: true,
  transports: {
    [flowMainnet.id]: http(),
    [mainnet.id]: http(),
  },
});
