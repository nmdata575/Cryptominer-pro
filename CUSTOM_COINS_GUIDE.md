# Custom Coins Guide - CryptoMiner Pro

## Overview

CryptoMiner Pro now supports adding custom cryptocurrencies! This feature allows you to mine any Scrypt-based cryptocurrency by providing the necessary parameters. This makes the system incredibly versatile for mining alternative coins, new cryptocurrencies, or testing purposes.

## Features

- ✅ **Add Custom Coins**: Define your own cryptocurrency parameters
- ✅ **Real-time Validation**: Instant validation of coin parameters
- ✅ **Import/Export**: Backup and share coin configurations
- ✅ **Full Integration**: Custom coins work with all mining features
- ✅ **Address Validation**: Support for multiple address formats
- ✅ **Pool Configuration**: Default pool settings for each coin
- ✅ **Rich Metadata**: Store additional information about coins

## Adding Custom Coins

### Method 1: Using the Web Interface

1. **Access the Custom Coin Manager**
   - Click "Manage Custom Coins" in the coin selector
   - The Custom Coin Manager modal will open

2. **Add New Coin**
   - Click "Add Custom Coin"
   - Fill in the required information
   - Click "Add Coin" to save

3. **Required Information**
   - **Coin ID**: Unique identifier (lowercase, letters, numbers, hyphens, underscores)
   - **Name**: Human-readable name
   - **Symbol**: Ticker symbol (e.g., VTC, NVC)
   - **Algorithm**: Scrypt, Scrypt-N, or Scrypt-Jane
   - **Block Time Target**: Target time between blocks (seconds)
   - **Block Reward**: Reward per block
   - **Network Difficulty**: Current network difficulty
   - **Scrypt Parameters**: N, r, p values

### Method 2: Using the API

```bash
curl -X POST http://localhost:8001/api/coins/custom \
  -H "Content-Type: application/json" \
  -d '{
    "id": "mycoin",
    "name": "My Custom Coin",
    "symbol": "MYC",
    "algorithm": "scrypt",
    "block_time_target": 150,
    "block_reward": 50,
    "network_difficulty": 1000000,
    "scrypt_params": {
      "N": 1024,
      "r": 1,
      "p": 1
    },
    "address_formats": [{
      "type": "standard",
      "prefix": "M",
      "description": "Standard MyCoin address"
    }],
    "metadata": {
      "description": "My custom cryptocurrency for testing"
    }
  }'
```

## Real-World Examples

### 1. Vertcoin (VTC)
```json
{
  "id": "vertcoin",
  "name": "Vertcoin",
  "symbol": "VTC",
  "algorithm": "scrypt",
  "block_time_target": 150,
  "block_reward": 25,
  "network_difficulty": 2500000,
  "scrypt_params": {
    "N": 1024,
    "r": 1,
    "p": 1
  },
  "address_formats": [{
    "type": "legacy",
    "prefix": "V",
    "description": "Legacy Vertcoin address"
  }, {
    "type": "segwit",
    "prefix": "vtc1",
    "description": "Segwit Vertcoin address"
  }],
  "pool_settings": {
    "default_pool_address": "stratum+tcp://vtc.pool.com",
    "default_pool_port": 3333,
    "default_pool_username": "your_wallet_address.worker1"
  },
  "metadata": {
    "description": "The People's Coin - ASIC resistant cryptocurrency",
    "website": "https://vertcoin.org",
    "blockchain_explorer": "https://insight.vertcoin.org",
    "github_repository": "https://github.com/vertcoin-project/vertcoin-core"
  }
}
```

### 2. Syscoin (SYS)
```json
{
  "id": "syscoin",
  "name": "Syscoin",
  "symbol": "SYS",
  "algorithm": "scrypt",
  "block_time_target": 60,
  "block_reward": 15,
  "network_difficulty": 1800000,
  "scrypt_params": {
    "N": 1024,
    "r": 1,
    "p": 1
  },
  "address_formats": [{
    "type": "standard",
    "prefix": "S",
    "description": "Standard Syscoin address"
  }],
  "metadata": {
    "description": "Blockchain platform for business applications"
  }
}
```

### 3. Einsteinium (EMC2)
```json
{
  "id": "einsteinium",
  "name": "Einsteinium",
  "symbol": "EMC2",
  "algorithm": "scrypt",
  "block_time_target": 60,
  "block_reward": 1024,
  "network_difficulty": 800000,
  "scrypt_params": {
    "N": 1024,
    "r": 1,
    "p": 1
  },
  "address_formats": [{
    "type": "standard",
    "prefix": "E",
    "description": "Standard Einsteinium address"
  }],
  "metadata": {
    "description": "Cryptocurrency funding scientific research"
  }
}
```

## Scrypt Parameters Guide

### Understanding Scrypt Parameters

- **N**: CPU/Memory cost parameter (must be power of 2)
- **r**: Block size parameter
- **p**: Parallelization parameter

### Common Configurations

| Coin Type | N | r | p | Memory Usage | Notes |
|-----------|---|---|---|--------------|-------|
| Standard | 1024 | 1 | 1 | Low | Most compatible |
| High Security | 2048 | 1 | 1 | Medium | More secure |
| Memory Hard | 4096 | 2 | 1 | High | ASIC resistant |

### Validation Rules

- N must be a power of 2 (1024, 2048, 4096, etc.)
- r must be >= 1
- p must be >= 1
- N × r × p should be reasonable (< 1,000,000)

## Address Formats

### Supported Types

1. **Standard**: Basic address format
2. **Legacy**: Traditional address format
3. **Segwit**: Segregated witness addresses
4. **Multisig**: Multi-signature addresses

### Examples

```json
"address_formats": [
  {
    "type": "legacy",
    "prefix": "L",
    "description": "Legacy Litecoin address"
  },
  {
    "type": "segwit",
    "prefix": "ltc1",
    "description": "Segwit Litecoin address"
  }
]
```

## Pool Configuration

### Default Pool Settings

```json
"pool_settings": {
  "default_pool_address": "stratum+tcp://pool.example.com",
  "default_pool_port": 3333,
  "default_pool_username": "wallet_address.worker1"
}
```

### RPC Settings

```json
"rpc_settings": {
  "default_rpc_host": "localhost",
  "default_rpc_port": 8332,
  "default_rpc_username": "rpcuser",
  "default_rpc_password": "rpcpass"
}
```

## API Endpoints

### Custom Coin Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/coins/custom` | List all custom coins |
| GET | `/api/coins/custom/{id}` | Get specific coin |
| POST | `/api/coins/custom` | Add new coin |
| PUT | `/api/coins/custom/{id}` | Update coin |
| DELETE | `/api/coins/custom/{id}` | Delete coin |

### Validation and Import/Export

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/coins/custom/validate` | Validate coin config |
| GET | `/api/coins/custom/export` | Export all coins |
| POST | `/api/coins/custom/import` | Import coins |

## Mining with Custom Coins

### Starting Mining

```bash
curl -X POST http://localhost:8001/api/mining/start \
  -H "Content-Type: application/json" \
  -d '{
    "coin": "vertcoin",
    "mode": "pool",
    "threads": 4,
    "intensity": 0.8,
    "wallet_address": "VtcWalletAddress12345",
    "pool_username": "VtcWalletAddress12345.worker1",
    "pool_password": "x"
  }'
```

### Mining Status

```bash
curl http://localhost:8001/api/mining/status
```

## Import/Export Coins

### Export Configuration

```bash
curl http://localhost:8001/api/coins/custom/export > my_coins.json
```

### Import Configuration

```bash
curl -X POST http://localhost:8001/api/coins/custom/import \
  -H "Content-Type: application/json" \
  -d @my_coins.json
```

## Best Practices

### 1. Research Before Adding

- Verify the coin uses Scrypt algorithm
- Check official documentation for parameters
- Ensure the coin is actively maintained

### 2. Use Standard Parameters

- Start with N=1024, r=1, p=1 for compatibility
- Only increase if specifically required
- Test with low intensity first

### 3. Address Format Validation

- Include all supported address formats
- Use correct prefixes for each type
- Test address validation before mining

### 4. Pool Configuration

- Use reliable pool addresses
- Configure backup pools if available
- Test pool connectivity before mining

### 5. Metadata Management

- Include comprehensive descriptions
- Add official website links
- Document any special requirements

## Troubleshooting

### Common Issues

1. **Validation Errors**
   - Check Scrypt parameters are valid
   - Ensure N is a power of 2
   - Verify required fields are present

2. **Mining Fails**
   - Validate wallet address format
   - Check pool connectivity
   - Verify coin parameters match network

3. **Address Validation**
   - Update address formats for the coin
   - Test with known valid addresses
   - Check prefix configurations

### Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| "Coin ID already exists" | Duplicate ID | Use unique identifier |
| "Invalid scrypt parameters" | Wrong N/r/p values | Use valid parameters |
| "Validation failed" | Missing fields | Complete all required fields |

## Security Considerations

1. **Verify Coin Legitimacy**
   - Research the cryptocurrency project
   - Check community and development activity
   - Verify it's not a scam coin

2. **Pool Security**
   - Use reputable mining pools
   - Verify pool addresses and ports
   - Monitor for unusual activity

3. **Wallet Security**
   - Use secure wallet addresses
   - Never share private keys
   - Regular security audits

## Future Enhancements

- **Auto-discovery**: Automatic parameter detection
- **Pool Integration**: Direct pool discovery
- **Market Data**: Price and profitability information
- **Community Sharing**: Shared coin configurations
- **Advanced Validation**: Network connectivity tests

## Support

For issues with custom coins:

1. Check the validation endpoint first
2. Verify all required parameters
3. Test with known working configurations
4. Consult the cryptocurrency's official documentation

---

**Happy Mining with Custom Coins!** 🚀💰

*This feature makes CryptoMiner Pro incredibly versatile for mining any Scrypt-based cryptocurrency.*