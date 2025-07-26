/**
 * Crypto Utilities - Node.js Implementation
 * Cryptographic functions for mining operations
 */

const crypto = require('crypto');
const CryptoJS = require('crypto-js');

class CryptoUtils {
  /**
   * Generate secure random bytes
   */
  randomBytes(length) {
    return crypto.randomBytes(length);
  }

  /**
   * Generate secure random hex string
   */
  randomHex(length) {
    return crypto.randomBytes(length).toString('hex');
  }

  /**
   * SHA256 hash function
   */
  sha256(data) {
    return crypto.createHash('sha256').update(data).digest();
  }

  /**
   * SHA256 hash to hex string
   */
  sha256Hex(data) {
    return crypto.createHash('sha256').update(data).digest('hex');
  }

  /**
   * Double SHA256 (used in Bitcoin-like cryptocurrencies)
   */
  doubleSha256(data) {
    const hash1 = crypto.createHash('sha256').update(data).digest();
    const hash2 = crypto.createHash('sha256').update(hash1).digest();
    return hash2;
  }

  /**
   * Double SHA256 to hex string
   */
  doubleSha256Hex(data) {
    return this.doubleSha256(data).toString('hex');
  }

  /**
   * Simple Scrypt implementation using available crypto
   * Note: This is a simplified version for demonstration
   */
  scrypt(password, salt, N = 1024, r = 1, p = 1, dkLen = 32) {
    try {
      // Use Node.js built-in scrypt if available
      if (crypto.scrypt) {
        return new Promise((resolve, reject) => {
          crypto.scrypt(password, salt, dkLen, { N, r, p }, (err, derivedKey) => {
            if (err) reject(err);
            else resolve(derivedKey);
          });
        });
      }
      
      // Fallback to crypto-js scrypt
      const key = CryptoJS.PBKDF2(password, salt, {
        keySize: dkLen / 4,
        iterations: N,
        hasher: CryptoJS.algo.SHA256
      });
      
      return Promise.resolve(Buffer.from(key.toString(CryptoJS.enc.Hex), 'hex'));
    } catch (error) {
      // Ultimate fallback to repeated hashing
      let result = Buffer.concat([Buffer.from(password), Buffer.from(salt)]);
      for (let i = 0; i < N; i++) {
        result = crypto.createHash('sha256').update(result).digest();
      }
      return Promise.resolve(result);
    }
  }

  /**
   * Scrypt synchronous version
   */
  scryptSync(password, salt, N = 1024, r = 1, p = 1, dkLen = 32) {
    try {
      // Use Node.js built-in scrypt if available
      if (crypto.scryptSync) {
        return crypto.scryptSync(password, salt, dkLen, { N, r, p });
      }
      
      // Fallback to repeated hashing
      let result = Buffer.concat([Buffer.from(password), Buffer.from(salt)]);
      for (let i = 0; i < N; i++) {
        result = crypto.createHash('sha256').update(result).digest();
      }
      return result;
    } catch (error) {
      console.error('Scrypt error:', error);
      return crypto.createHash('sha256').update(password + salt).digest();
    }
  }

  /**
   * HMAC-SHA256
   */
  hmacSha256(key, data) {
    return crypto.createHmac('sha256', key).update(data).digest();
  }

  /**
   * HMAC-SHA256 to hex string
   */
  hmacSha256Hex(key, data) {
    return crypto.createHmac('sha256', key).update(data).digest('hex');
  }

  /**
   * RIPEMD160 hash
   */
  ripemd160(data) {
    return crypto.createHash('ripemd160').update(data).digest();
  }

  /**
   * RIPEMD160 to hex string
   */
  ripemd160Hex(data) {
    return crypto.createHash('ripemd160').update(data).digest('hex');
  }

  /**
   * Hash160 (SHA256 followed by RIPEMD160)
   */
  hash160(data) {
    const sha256Hash = crypto.createHash('sha256').update(data).digest();
    return crypto.createHash('ripemd160').update(sha256Hash).digest();
  }

  /**
   * Hash160 to hex string
   */
  hash160Hex(data) {
    return this.hash160(data).toString('hex');
  }

  /**
   * Generate merkle root from transactions
   */
  calculateMerkleRoot(transactions) {
    if (!transactions || transactions.length === 0) {
      return crypto.createHash('sha256').update('').digest();
    }
    
    if (transactions.length === 1) {
      return this.doubleSha256(transactions[0]);
    }
    
    const hashes = transactions.map(tx => this.doubleSha256(tx));
    
    while (hashes.length > 1) {
      const newHashes = [];
      
      for (let i = 0; i < hashes.length; i += 2) {
        let combined;
        if (i + 1 < hashes.length) {
          combined = Buffer.concat([hashes[i], hashes[i + 1]]);
        } else {
          // If odd number, duplicate the last hash
          combined = Buffer.concat([hashes[i], hashes[i]]);
        }
        newHashes.push(this.doubleSha256(combined));
      }
      
      hashes.splice(0, hashes.length, ...newHashes);
    }
    
    return hashes[0];
  }

  /**
   * Verify hash meets difficulty target
   */
  verifyDifficulty(hash, difficulty) {
    const hashBuffer = Buffer.isBuffer(hash) ? hash : Buffer.from(hash, 'hex');
    const target = this.difficultyToTarget(difficulty);
    return this.compareBuffers(hashBuffer, target) <= 0;
  }

  /**
   * Convert difficulty to target
   */
  difficultyToTarget(difficulty) {
    // Simplified difficulty to target conversion
    const maxTarget = Buffer.from('00000000FFFF0000000000000000000000000000000000000000000000000000', 'hex');
    const target = Buffer.alloc(32);
    
    // Simple approximation
    const targetValue = BigInt('0x' + maxTarget.toString('hex')) / BigInt(difficulty);
    const targetHex = targetValue.toString(16).padStart(64, '0');
    
    return Buffer.from(targetHex, 'hex');
  }

  /**
   * Compare two buffers
   */
  compareBuffers(a, b) {
    for (let i = 0; i < Math.min(a.length, b.length); i++) {
      if (a[i] < b[i]) return -1;
      if (a[i] > b[i]) return 1;
    }
    return a.length - b.length;
  }

  /**
   * Generate random nonce
   */
  generateNonce() {
    return crypto.randomBytes(4).readUInt32BE(0);
  }

  /**
   * Convert number to little-endian buffer
   */
  numberToLE(num, bytes = 4) {
    const buffer = Buffer.alloc(bytes);
    buffer.writeUIntLE(num, 0, bytes);
    return buffer;
  }

  /**
   * Convert number to big-endian buffer
   */
  numberToBE(num, bytes = 4) {
    const buffer = Buffer.alloc(bytes);
    buffer.writeUIntBE(num, 0, bytes);
    return buffer;
  }

  /**
   * Convert buffer to hex string with prefix
   */
  bufferToHex(buffer, prefix = '0x') {
    return prefix + buffer.toString('hex');
  }

  /**
   * Convert hex string to buffer
   */
  hexToBuffer(hex) {
    const cleanHex = hex.replace(/^0x/, '');
    return Buffer.from(cleanHex, 'hex');
  }

  /**
   * Reverse buffer bytes (useful for endianness conversion)
   */
  reverseBuffer(buffer) {
    return Buffer.from(buffer).reverse();
  }

  /**
   * Generate timestamp
   */
  generateTimestamp() {
    return Math.floor(Date.now() / 1000);
  }

  /**
   * Validate hex string
   */
  isValidHex(str) {
    return /^[0-9a-fA-F]+$/.test(str.replace(/^0x/, ''));
  }

  /**
   * Generate secure token
   */
  generateSecureToken(length = 32) {
    return crypto.randomBytes(length).toString('hex');
  }

  /**
   * Hash password with salt
   */
  hashPassword(password, salt) {
    return crypto.createHash('sha256').update(password + salt).digest('hex');
  }

  /**
   * Verify password hash
   */
  verifyPassword(password, salt, hash) {
    const computedHash = this.hashPassword(password, salt);
    return computedHash === hash;
  }

  /**
   * Generate salt
   */
  generateSalt(length = 16) {
    return crypto.randomBytes(length).toString('hex');
  }

  /**
   * Constant time comparison
   */
  constantTimeCompare(a, b) {
    if (a.length !== b.length) return false;
    
    let result = 0;
    for (let i = 0; i < a.length; i++) {
      result |= a.charCodeAt(i) ^ b.charCodeAt(i);
    }
    
    return result === 0;
  }
}

module.exports = new CryptoUtils();