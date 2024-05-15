# Realtime Betting Game on L3 OP-MODE-CELESTIA CHAIN

Welcome to the Realtime Betting Game built on the L3 OP-MODE-CELESTIA Chain! This project brings the excitement of betting on a roulette-style game to the blockchain. Players can wager on various outcomes and see results in real-time, all powered by GELLATO VRF, Hyperlane, and Kurtoris technologies.

## How to Play

1. **Place Your Bet**: Choose from different betting options, including:
   - Betting on a single number (0-36)
   - Betting on even or odd numbers
   - Betting on black or red colors
   - Betting on the first or second halves of the table
   - Betting on the first, second, or third thirds of the table

2. **Submit Your Wager**: Each bet requires a minimum of 0.001 ETH to play. You can place your bet by calling the corresponding function with your chosen parameters.

3. **Spin the Wheel**: After placing your bet, call the `spinBettingWheel()` function to spin the wheel and determine the outcome.

4. **Collect Your Winnings**: If your bet is successful, you'll receive payouts based on the odds of your chosen outcome. Payouts range from 2:1 to 35:1, depending on the type of bet.

## Betting Options

- **Single Number**: Bet on a specific number from 0 to 36.
- **Even/Odd**: Bet on whether the winning number will be even or odd.
- **Black/Red**: Bet on whether the winning number will be black or red.
- **First/Second Half**: Bet on whether the winning number will be in the first or second half of the table.
- **First/Second/Third Third**: Bet on whether the winning number will be in the first, second, or third third of the table.

## Smart Contract Details

- **Minimum Bet**: 0.001 ETH
- **House Balance**: The contract ensures that the house (contract) and sponsor wallet remain solvent. If the house balance is too low, it can be refilled by sending ETH directly to the contract address.
- **Random Number Generation**: The contract utilizes GELLATO VRF (Verifiable Random Function) for secure and unbiased random number generation.
- **Interchain Security Module**: Provides additional security measures for interchain communication.

## Getting Started

To start playing, interact with the contract functions using a compatible Ethereum wallet or decentralized application (dApp) interface.

Enjoy the excitement of real-time betting on the blockchain with the Realtime Betting Game on L3 OP-MODE_CELESTIA CHAIN!

---
**Disclaimer**: This project is provided under the MIT License. Play responsibly and ensure compliance with local regulations.
