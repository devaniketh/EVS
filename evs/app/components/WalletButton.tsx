"use client";

import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useWallet } from "../hooks/useWallet";

export function WalletButton() {
  const { isConnected, balance, address } = useWallet();

  return (
    <div className="fixed top-4 right-4 z-50">
      <ConnectButton />
      {isConnected && (
        <div className="mt-2 p-2 bg-black bg-opacity-70 rounded-lg text-white text-sm">
          <div>Balance: {balance} ETH</div>
          <div className="text-xs opacity-70">
            {address?.slice(0, 6)}...{address?.slice(-4)}
          </div>
        </div>
      )}
    </div>
  );
}
