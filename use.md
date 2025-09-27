How to use `spotTrade.ts` :

```
import { Wallet } from "ethers";
import { executeSpotTradeWith1inch } from "./spotTrade1inch";
import { HyperliquidPositionOpener } from "./hlopen";
// ... import your other classes as needed

const wallet = new Wallet(PRIVATE_KEY, PROVIDER);
const oneInchConfig = { apiKey: ONEINCH_API_KEY, chainId: 1 };

const spotResult = await executeSpotTradeWith1inch(
  wallet,
  ethers.utils.parseUnits(spotUsdcAmount, 6).toString(),
  oneInchConfig
);
if (!spotResult.txHash) throw new Error(spotResult.error);

// Now hedge the spot position with Hyperliquid (using your hlopen.ts logic)
```