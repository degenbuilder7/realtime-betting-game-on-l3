3.10

hyperlane deploy core --targets sepolia,gaming --chains ./configs/chains.yaml --ism ./configs/ism.yaml --key 0xkey


hyperlane deploy kurtosis-agents

configure/set ISM

{
  "chainId": 60385,
  "name": "gamingonl3",
  "protocol": "ethereum",
  "rpcUrls": [{ "http": "https://rpc-useful-aquamarine-rhinoceros-dufw1ydgcn.t.conduit.xyz" }],
  "blockExplorers": [ {
      "name": "blockscout",
      "family": "blockscout",
      "url": "https://explorer.testnet.inco.org",
      "apiUrl": "https://explorer.testnet.inco.org/api/v2",
      "apiKey": ""
  } ],
  "blocks": { "confirmations": 1, "estimateBlockTime": 13 },
  "mailbox": "0xc93136D181C3911Df29771d880Bdf6AC4B6f2335",
}
