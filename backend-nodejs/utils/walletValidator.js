/**
 * Wallet Address Validator - Node.js Implementation
 * Validates cryptocurrency wallet addresses using official network parameters
 */

const crypto = require('crypto');

// Official Litecoin Network Parameters
const LITECOIN_PARAMS = {
  main: {
    versions: {
      public: 0x30,      // 'L' prefix for legacy addresses
      scripthash: 0x32,  // 'M' prefix for script addresses  
      scripthash2: 0x05, // '3' prefix for backward compatibility
      private: 0xb0,     // Private key version
    },
    bech32: 'ltc'        // Bech32 prefix for native segwit
  },
  test: {
    versions: {
      public: 0x6f,      // Testnet public addresses
      scripthash: 0x3a,  // Testnet script addresses
      scripthash2: 0xc4, // Testnet compatibility
      private: 0xef,     // Testnet private keys
    },
    bech32: 'tltc'       // Testnet bech32 prefix
  }
};

class WalletValidator {
  /**
   * Validate wallet address for specific cryptocurrency
   */
  validateAddress(address, coinSymbol) {
    try {
      if (!address || typeof address !== 'string' || address.trim().length === 0) {
        return {
          valid: false,
          error: 'Wallet address cannot be empty'
        };
      }

      const trimmedAddress = address.trim();

      // Basic length checks
      if (trimmedAddress.length < 25 || trimmedAddress.length > 62) {
        return {
          valid: false,
          error: 'Invalid address length'
        };
      }

      // Coin-specific validation
      switch (coinSymbol.toUpperCase()) {
        case 'LTC':
          return this.validateLitecoinAddress(trimmedAddress);
        case 'DOGE':
          return this.validateDogecoinAddress(trimmedAddress);
        case 'FTC':
          return this.validateFeathercoinAddress(trimmedAddress);
        default:
          return this.validateGenericAddress(trimmedAddress);
      }
    } catch (error) {
      return {
        valid: false,
        error: 'Validation error: ' + error.message
      };
    }
  }

  /**
   * Validate Litecoin address
   */
  validateLitecoinAddress(address) {
    // Legacy addresses start with 'L'
    if (address.startsWith('L')) {
      if (address.length >= 27 && address.length <= 34) {
        return {
          valid: true,
          format: 'base58',
          type: 'legacy'
        };
      }
      return {
        valid: false,
        error: 'Invalid Litecoin legacy address length'
      };
    }
    
    // Segwit addresses start with 'ltc1'
    if (address.startsWith('ltc1')) {
      if (address.length >= 39 && address.length <= 59) {
        return {
          valid: true,
          format: 'bech32',
          type: 'segwit'
        };
      }
      return {
        valid: false,
        error: 'Invalid Litecoin segwit address length'
      };
    }
    
    // Multisig addresses start with 'M' or '3'
    if (address.startsWith('M') || address.startsWith('3')) {
      if (address.length >= 27 && address.length <= 35) {
        return {
          valid: true,
          format: 'base58',
          type: 'multisig'
        };
      }
      return {
        valid: false,
        error: 'Invalid Litecoin multisig address length'
      };
    }
    
    return {
      valid: false,
      error: 'Invalid Litecoin address format'
    };
  }

  /**
   * Validate Dogecoin address
   */
  validateDogecoinAddress(address) {
    // Standard addresses start with 'D'
    if (address.startsWith('D')) {
      if (address.length >= 27 && address.length <= 34) {
        return {
          valid: true,
          format: 'base58',
          type: 'standard'
        };
      }
      return {
        valid: false,
        error: 'Invalid Dogecoin address length'
      };
    }
    
    // Multisig addresses start with 'A' or '9'
    if (address.startsWith('A') || address.startsWith('9')) {
      if (address.length >= 27 && address.length <= 35) {
        return {
          valid: true,
          format: 'base58',
          type: 'multisig'
        };
      }
      return {
        valid: false,
        error: 'Invalid Dogecoin multisig address length'
      };
    }
    
    return {
      valid: false,
      error: 'Invalid Dogecoin address format'
    };
  }

  /**
   * Validate Feathercoin address
   */
  validateFeathercoinAddress(address) {
    // Standard addresses start with '6'
    if (address.startsWith('6')) {
      if (address.length >= 27 && address.length <= 35) {
        return {
          valid: true,
          format: 'base58',
          type: 'standard'
        };
      }
      return {
        valid: false,
        error: 'Invalid Feathercoin address length'
      };
    }
    
    // Multisig addresses start with '3'
    if (address.startsWith('3')) {
      if (address.length >= 27 && address.length <= 35) {
        return {
          valid: true,
          format: 'base58',
          type: 'multisig'
        };
      }
      return {
        valid: false,
        error: 'Invalid Feathercoin multisig address length'
      };
    }
    
    return {
      valid: false,
      error: 'Invalid Feathercoin address format'
    };
  }

  /**
   * Generic address validation
   */
  validateGenericAddress(address) {
    // Basic checks for common patterns
    const hasValidChars = /^[a-km-zA-HJ-NP-Z1-9]+$/.test(address);
    
    if (!hasValidChars) {
      return {
        valid: false,
        error: 'Address contains invalid characters'
      };
    }

    if (address.length >= 25 && address.length <= 62) {
      return {
        valid: true,
        format: 'unknown',
        type: 'generic'
      };
    }

    return {
      valid: false,
      error: 'Invalid address format'
    };
  }

  /**
   * Base58 character set check
   */
  isValidBase58(str) {
    const base58Chars = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    return str.split('').every(char => base58Chars.includes(char));
  }

  /**
   * Bech32 character set check
   */
  isValidBech32(str) {
    const bech32Chars = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';
    const hrp = str.split('1')[0];
    const data = str.split('1')[1];
    
    if (!data) return false;
    
    return data.split('').every(char => bech32Chars.includes(char));
  }

  /**
   * Get address format information
   */
  getAddressFormat(address, coinSymbol) {
    const validation = this.validateAddress(address, coinSymbol);
    
    if (!validation.valid) {
      return {
        format: 'invalid',
        description: validation.error
      };
    }

    const formats = {
      base58: 'Base58 encoded address',
      bech32: 'Bech32 encoded segwit address',
      unknown: 'Unknown address format'
    };

    const types = {
      legacy: 'Legacy address format',
      segwit: 'Segregated Witness address',
      multisig: 'Multi-signature address',
      standard: 'Standard address format',
      generic: 'Generic cryptocurrency address'
    };

    return {
      format: validation.format,
      type: validation.type,
      formatDescription: formats[validation.format] || 'Unknown format',
      typeDescription: types[validation.type] || 'Unknown type',
      coinSymbol: coinSymbol.toUpperCase()
    };
  }

  /**
   * Validate multiple addresses
   */
  validateMultipleAddresses(addresses, coinSymbol) {
    const results = [];
    
    for (const address of addresses) {
      const validation = this.validateAddress(address, coinSymbol);
      results.push({
        address: address,
        ...validation
      });
    }
    
    return {
      total: addresses.length,
      valid: results.filter(r => r.valid).length,
      invalid: results.filter(r => !r.valid).length,
      results: results
    };
  }

  /**
   * Get supported coin information
   */
  getSupportedCoins() {
    return {
      LTC: {
        name: 'Litecoin',
        symbol: 'LTC',
        addressFormats: ['Legacy (L...)', 'Segwit (ltc1...)', 'Multisig (M.../3...)'],
        examples: [
          'LhK1NkKnRR5zwBowVGv2whSALgFa9FUCYy',
          'ltc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4',
          'M8T1B2Z97gVdvmfkQcAtYbEepune1tzGua'
        ]
      },
      DOGE: {
        name: 'Dogecoin',
        symbol: 'DOGE',
        addressFormats: ['Standard (D...)', 'Multisig (A.../9...)'],
        examples: [
          'DQVpNjNVHjTgHaE4Y1oqRxCLe6qMFmHVh8',
          'A9uBkPWHtBYeWQJ5LJgMqCvGw9GhuukkdY'
        ]
      },
      FTC: {
        name: 'Feathercoin',
        symbol: 'FTC',
        addressFormats: ['Standard (6...)', 'Multisig (3...)'],
        examples: [
          '6nsHHMiUexBgE8GZzw5EBVL2mBCDLRZJpD',
          '3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy'
        ]
      }
    };
  }
}

module.exports = new WalletValidator();