"use client";

import {
  useAccount,
  useConnect,
  useDisconnect,
  useBalance,
  useWriteContract,
  useWaitForTransactionReceipt,
} from "wagmi";
import { injected, metaMask, walletConnect } from "wagmi/connectors";
import { parseEther, formatEther } from "viem";

export function useWallet() {
  const { address, isConnected, chainId } = useAccount();
  const { connect, connectors, isPending } = useConnect();
  const { disconnect } = useDisconnect();
  const { data: balance } = useBalance({ address });
  const {
    writeContract,
    data: hash,
    isPending: isWritePending,
    error: writeError,
  } = useWriteContract();
  const { isLoading: isConfirming, isSuccess: isConfirmed } =
    useWaitForTransactionReceipt({
      hash,
    });

  const connectWallet = async (connectorId: string) => {
    const connector = connectors.find((c) => c.id === connectorId);
    if (connector) {
      await connect({ connector });
    }
  };

  const sendTransaction = async (to: string, value: string) => {
    if (!address) return;

    try {
      await writeContract({
        address: to as `0x${string}`,
        abi: [],
        functionName: "transfer",
        args: [address, parseEther(value)],
      });
    } catch (error) {
      console.error("Transaction failed:", error);
    }
  };

  const getFormattedBalance = () => {
    if (!balance) return "0.00";
    return formatEther(balance.value);
  };

  return {
    address,
    isConnected,
    chainId,
    balance: getFormattedBalance(),
    connectWallet,
    disconnect,
    sendTransaction,
    isPending,
    isWritePending,
    isConfirming,
    isConfirmed,
    writeError,
    hash,
  };
}
