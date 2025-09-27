// @ts-ignore
import axios from "axios";
// @ts-ignore
import { ethers, Wallet } from "ethers";

// Update these addresses as needed for your asset
const USDC_ADDRESS = "0xA0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"; // USDC mainnet
const ETH_ADDRESS = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"; // Native ETH for 1inch
const ONEINCH_API_V6_URL = "https://api.1inch.dev/swap/v6.1";

interface OneInchConfig {
  apiKey: string;
  chainId: number;
}

export async function executeSpotTradeWith1inch(
  wallet: Wallet,
  amountUsdc: string, // In units of 6 decimals
  config: OneInchConfig
): Promise<{ txHash?: string; error?: string; amountReceived?: string }> {
  const { apiKey, chainId } = config;

  // Step 1: Get a quote from 1inch
  const quoteRes = await axios.get(`${ONEINCH_API_V6_URL}/${chainId}/quote`, {
    params: {
      src: USDC_ADDRESS,
      dst: ETH_ADDRESS,
      amount: amountUsdc,
      includeGas: "true",
    },
    headers: { Authorization: `Bearer ${apiKey}` },
  });
  if (!quoteRes.data?.toAmount) {
    return { error: "1inch quote unavailable" };
  }
  const expectedEth = ethers.utils.formatEther(quoteRes.data.toAmount);

  // Step 2: Build swap transaction
  const swapRes = await axios.get(`${ONEINCH_API_V6_URL}/${chainId}/swap`, {
    params: {
      src: USDC_ADDRESS,
      dst: ETH_ADDRESS,
      amount: amountUsdc,
      from: wallet.address,
      slippage: "1", // Edit slippage tolerance as needed
      disableEstimate: "true",
      allowPartialFill: "false",
    },
    headers: { Authorization: `Bearer ${apiKey}` },
  });

  const tx = swapRes.data.tx;
  if (!tx?.to || !tx.data) {
    return { error: "1inch swap tx unavailable" };
  }

  // Step 3: Send transaction
  const response = await wallet.sendTransaction({
    to: tx.to,
    data: tx.data,
    value: ethers.BigNumber.from(tx.value || "0"),
    gasLimit: tx.gas, // Optional
    gasPrice: tx.gasPrice, // Optional
  });
  await response.wait();

  return {
    txHash: response.hash,
    amountReceived: expectedEth,
  };
}
