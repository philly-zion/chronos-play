# ChronosPlay 🎮⏰

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Clarity Version](https://img.shields.io/badge/Clarity-v3-blue.svg)](https://docs.stacks.co/clarity)
[![Stacks](https://img.shields.io/badge/Built%20for-Stacks-orange.svg)](https://stacks.org)

> Revolutionary time-locked gaming ecosystem powered by blockchain technology

## 🌟 Overview

ChronosPlay introduces a groundbreaking approach to gaming subscriptions where **time truly becomes your currency**. This smart contract creates an immersive subscription model that leverages Stacks blockchain's block-height mechanism to deliver precise, trustless gaming access control.

Players purchase gaming time measured in blockchain blocks, ensuring transparent, verifiable playtime allocation while enabling flexible tier-based progression systems.

## ✨ Key Features

### 🔐 Trustless Time Management

- **Block-based subscriptions**: Gaming time measured in Stacks blockchain blocks
- **Precise timing**: Leverage blockchain's immutable timestamp for accurate playtime tracking
- **Transparent calculations**: All subscription costs and durations are publicly verifiable

### 🎯 Tier-Based Gaming

- **Multiple tiers**: From Casual Explorer to Elite Commander
- **Flexible pricing**: Different cost-per-block rates for various gaming experiences
- **Customizable durations**: Minimum and maximum subscription periods per tier

### 💫 Advanced Subscription Management

- **Auto-renewal**: Set-and-forget subscription management
- **Playtime extension**: Add more blocks to existing subscriptions
- **Instant cancellation**: Quit subscriptions at any time
- **Real-time tracking**: Monitor remaining play blocks

### 🛡️ Security & Safety

- **Overflow protection**: Safe arithmetic operations prevent integer overflow attacks
- **Input validation**: Comprehensive validation for all user inputs
- **Access control**: Role-based permissions for administrative functions
- **Emergency controls**: Game master can update tiers and transfer control

## 🏗️ Architecture

### Smart Contract Structure

```
ChronosPlay Contract
├── Constants & Error Handling
├── State Variables
├── Data Storage Maps
│   ├── gaming-tiers
│   ├── player-profiles
│   └── subscription-ledger
├── Validation Helper Functions
├── Read-Only Functions
├── Public Functions (Player Operations)
└── Administrative Functions
```

### Core Data Structures

#### Gaming Tiers

```clarity
{
  name: (string-ascii 64),
  cost-per-block: uint,
  minimum-duration: uint,
  maximum-duration: uint,
  active: bool
}
```

#### Player Profiles

```clarity
{
  player-id: uint,
  tier-id: uint,
  start-block: uint,
  end-block: uint,
  auto-renew: bool,
  total-spent: uint
}
```

## 🚀 Quick Start

### Prerequisites

- [Clarinet](https://docs.hiro.so/stacks/clarinet) v2.0+
- [Node.js](https://nodejs.org/) v18+
- [Stacks Wallet](https://www.hiro.so/wallet) for testnet interaction

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/philly-zion/chronos-play.git
   cd chronos-play
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Run tests**

   ```bash
   npm test
   ```

4. **Check contract syntax**

   ```bash
   clarinet check
   ```

### Development Setup

1. **Start local development environment**

   ```bash
   clarinet integrate
   ```

2. **Run tests with coverage**

   ```bash
   npm run test:report
   ```

3. **Watch mode for continuous testing**

   ```bash
   npm run test:watch
   ```

## 📖 Usage Guide

### For Players

#### 1. Join a Gaming Realm

```clarity
(contract-call? .chronos-play join-realm u1 u4320 true)
;; Parameters: tier-id, play-blocks, auto-renew
```

#### 2. Check Subscription Status

```clarity
(contract-call? .chronos-play is-subscription-valid 'SP1234...)
```

#### 3. Extend Playtime

```clarity
(contract-call? .chronos-play extend-playtime u2160)
;; Add 2160 blocks (~15 days)
```

#### 4. Toggle Auto-renewal

```clarity
(contract-call? .chronos-play toggle-auto-renew)
```

#### 5. View Remaining Blocks

```clarity
(contract-call? .chronos-play get-play-blocks-remaining 'SP1234...)
```

### For Administrators

#### 1. Create New Gaming Tier

```clarity
(contract-call? .chronos-play create-gaming-tier 
  "Pro Gamer" 
  u50 
  u4320 
  u26280 
)
```

#### 2. Update Existing Tier

```clarity
(contract-call? .chronos-play update-gaming-tier 
  u1 
  "Updated Casual" 
  u15 
  u4320 
  u52560 
  true
)
```

## 📊 Gaming Tiers

### Default Tiers

| Tier | Name | Cost/Block | Min Duration | Max Duration | Status |
|------|------|------------|--------------|--------------|--------|
| 1 | Casual Explorer | 12 STX | 4,320 blocks (~30 days) | 52,560 blocks (~365 days) | Active |
| 2 | Elite Commander | 25 STX | 4,320 blocks (~30 days) | 52,560 blocks (~365 days) | Active |

### Block Time Reference

- **1 block** ≈ 10 minutes
- **144 blocks** ≈ 1 day
- **4,320 blocks** ≈ 30 days
- **52,560 blocks** ≈ 365 days

## 🔧 API Reference

### Read-Only Functions

#### `get-gaming-tier`

Get tier information by ID.

```clarity
(get-gaming-tier (tier-id uint))
→ (optional {name: (string-ascii 64), cost-per-block: uint, ...})
```

#### `get-player-profile`

Get player's subscription profile.

```clarity
(get-player-profile (player principal))
→ (optional {player-id: uint, tier-id: uint, ...})
```

#### `is-subscription-valid`

Check if player has an active subscription.

```clarity
(is-subscription-valid (player principal))
→ bool
```

#### `calculate-subscription-cost`

Calculate total cost for tier and duration.

```clarity
(calculate-subscription-cost (tier-id uint) (play-blocks uint))
→ (response uint uint)
```

### Public Functions

#### `join-realm`

Subscribe to a gaming tier.

```clarity
(join-realm (tier-id uint) (play-blocks uint) (auto-renew bool))
→ (response uint uint)
```

#### `extend-playtime`

Add more blocks to existing subscription.

```clarity
(extend-playtime (additional-blocks uint))
→ (response uint uint)
```

#### `quit-realm`

Cancel subscription immediately.

```clarity
(quit-realm)
→ (response bool uint)
```

#### `toggle-auto-renew`

Toggle auto-renewal setting.

```clarity
(toggle-auto-renew)
→ (response bool uint)
```

## 🧪 Testing

### Running Tests

```bash
# Run all tests
npm test

# Run tests with coverage
npm run test:report

# Watch mode
npm run test:watch

# Check contract syntax
clarinet check
```

### Test Structure

```
tests/
└── chronos-play.test.ts    # Main test suite
```

### Example Test

```typescript
describe("ChronosPlay Tests", () => {
  it("should allow player to join realm", () => {
    const { result } = simnet.callPublicFn(
      "chronos-play",
      "join-realm",
      [Cl.uint(1), Cl.uint(4320), Cl.bool(true)],
      address1
    );
    expect(result).toBeOk(Cl.uint(1));
  });
});
```

## 🔒 Security Features

### Input Validation

- **Tier ID validation**: Ensures tier exists and is within bounds
- **Duration limits**: Prevents excessive subscription periods
- **Cost validation**: Protects against invalid pricing
- **Overflow protection**: Safe arithmetic operations

### Access Control

- **Game Master**: Administrative functions restricted to contract owner
- **Player permissions**: Users can only modify their own subscriptions
- **Transfer control**: Secure ownership transfer mechanism

### Error Handling

Comprehensive error codes for all failure scenarios:

- `ERR_ACCESS_DENIED` (u200)
- `ERR_INVALID_PLAY_DURATION` (u201)
- `ERR_INSUFFICIENT_FUNDS` (u202)
- `ERR_SUBSCRIPTION_ACTIVE` (u203)
- `ERR_NO_SUBSCRIPTION` (u204)
- `ERR_SUBSCRIPTION_EXPIRED` (u205)
- `ERR_INVALID_TIER` (u206)
- `ERR_INVALID_INPUT` (u207)
- `ERR_OVERFLOW` (u208)

## 🚀 Deployment

### Testnet Deployment

1. **Configure network settings**

   ```bash
   # Edit settings/Testnet.toml
   clarinet deployments generate --testnet
   ```

2. **Deploy to testnet**

   ```bash
   clarinet deployments apply --testnet
   ```

### Mainnet Deployment

1. **Configure production settings**

   ```bash
   # Edit settings/Mainnet.toml
   clarinet deployments generate --mainnet
   ```

2. **Deploy to mainnet** (requires funding)

   ```bash
   clarinet deployments apply --mainnet
   ```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Workflow

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

### Code Standards

- Follow Clarity best practices
- Add comprehensive tests
- Document all public functions
- Use descriptive variable names
- Include error handling

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Stacks Foundation** for the innovative blockchain platform
- **Hiro Systems** for excellent development tools
- **Clarity Language** for secure smart contract development
