"use strict";

/**
 * ricmoo/scrypt-js implementation
 * Pure JavaScript scrypt implementation for cryptocurrency mining
 * Source: https://github.com/ricmoo/scrypt-js/blob/master/scrypt.js
 */

const MAX_VALUE = 0x7fffffff;

// The SHA256 and PBKDF2 implementation are from scrypt-async-js:
// See: https://github.com/dchest/scrypt-async-js
function SHA256(m) {
    const K = new Uint32Array([
       0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b,
       0x59f111f1, 0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01,
       0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7,
       0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
       0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152,
       0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
       0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc,
       0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
       0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819,
       0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116, 0x1e376c08,
       0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f,
       0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
       0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
   ]);

    let h0 = 0x6a09e667, h1 = 0xbb67ae85, h2 = 0x3c6ef372, h3 = 0xa54ff53a;
    let h4 = 0x510e527f, h5 = 0x9b05688c, h6 = 0x1f83d9ab, h7 = 0x5be0cd19;
    const w = new Uint32Array(64);

    function blocks(p) {
        let off = 0, len = p.length;
        while (len >= 64) {
            let a = h0, b = h1, c = h2, d = h3, e = h4, f = h5, g = h6, h = h7, u, i, j, t1, t2;

            for (i = 0; i < 16; i++) {
                j = off + i*4;
                w[i] = ((p[j] & 0xff)<<24) | ((p[j+1] & 0xff)<<16) |
                ((p[j+2] & 0xff)<<8) | (p[j+3] & 0xff);
            }

            for (i = 16; i < 64; i++) {
                u = w[i-2];
                t1 = ((u>>>17) | (u<<(32-17))) ^ ((u>>>19) | (u<<(32-19))) ^ (u>>>10);

                u = w[i-15];
                t2 = ((u>>>7) | (u<<(32-7))) ^ ((u>>>18) | (u<<(32-18))) ^ (u>>>3);

                w[i] = (((t1 + w[i-7]) | 0) + ((t2 + w[i-16]) | 0)) | 0;
            }

            for (i = 0; i < 64; i++) {
                t1 = ((((((e>>>6) | (e<<(32-6))) ^ ((e>>>11) | (e<<(32-11))) ^
                  ((e>>>25) | (e<<(32-25)))) + ((e&f) ^ (~e&g))) | 0) +
                  ((h + ((K[i] + w[i]) | 0)) | 0)) | 0;

                t2 = ((((a>>>2) | (a<<(32-2))) ^ ((a>>>13) | (a<<(32-13))) ^
                  ((a>>>22) | (a<<(32-22)))) + ((a&b) ^ (a&c) ^ (b&c))) | 0;

                h = g;
                g = f;
                f = e;
                e = (d + t1) | 0;
                d = c;
                c = b;
                b = a;
                a = (t1 + t2) | 0;
            }

            h0 = (h0 + a) | 0;
            h1 = (h1 + b) | 0;
            h2 = (h2 + c) | 0;
            h3 = (h3 + d) | 0;
            h4 = (h4 + e) | 0;
            h5 = (h5 + f) | 0;
            h6 = (h6 + g) | 0;
            h7 = (h7 + h) | 0;

            off += 64;
            len -= 64;
        }
    }

    blocks(m);

    let i, bytesLeft = m.length % 64,
        bitLenHi = (m.length / 0x20000000) | 0,
        bitLenLo = m.length << 3,
        numZeros = (bytesLeft < 56) ? 56 : 120,
        p = m.slice(m.length - bytesLeft, m.length);

    p.push(0x80);
    for (i = bytesLeft + 1; i < numZeros; i++) { p.push(0); }
    p.push((bitLenHi >>> 24) & 0xff);
    p.push((bitLenHi >>> 16) & 0xff);
    p.push((bitLenHi >>> 8) & 0xff);
    p.push((bitLenHi >>> 0) & 0xff);
    p.push((bitLenLo >>> 24) & 0xff);
    p.push((bitLenLo >>> 16) & 0xff);
    p.push((bitLenLo >>> 8) & 0xff);
    p.push((bitLenLo >>> 0) & 0xff);

    blocks(p);

    return new Uint8Array([
        (h0 >>> 24) & 0xff, (h0 >>> 16) & 0xff, (h0 >>> 8) & 0xff, (h0 >>> 0) & 0xff,
        (h1 >>> 24) & 0xff, (h1 >>> 16) & 0xff, (h1 >>> 8) & 0xff, (h1 >>> 0) & 0xff,
        (h2 >>> 24) & 0xff, (h2 >>> 16) & 0xff, (h2 >>> 8) & 0xff, (h2 >>> 0) & 0xff,
        (h3 >>> 24) & 0xff, (h3 >>> 16) & 0xff, (h3 >>> 8) & 0xff, (h3 >>> 0) & 0xff,
        (h4 >>> 24) & 0xff, (h4 >>> 16) & 0xff, (h4 >>> 8) & 0xff, (h4 >>> 0) & 0xff,
        (h5 >>> 24) & 0xff, (h5 >>> 16) & 0xff, (h5 >>> 8) & 0xff, (h5 >>> 0) & 0xff,
        (h6 >>> 24) & 0xff, (h6 >>> 16) & 0xff, (h6 >>> 8) & 0xff, (h6 >>> 0) & 0xff,
        (h7 >>> 24) & 0xff, (h7 >>> 16) & 0xff, (h7 >>> 8) & 0xff, (h7 >>> 0) & 0xff
    ]);
}

function PBKDF2_HMAC_SHA256_OneIter(password, salt, dkLen) {
    // Simplified PBKDF2 for one iteration (as used in scrypt)
    const hLen = 32;
    const U = new Uint8Array(hLen);
    const T = new Uint8Array(hLen);
    const blockIndex = new Uint8Array(4);
    
    // Single iteration PBKDF2
    for (let i = 0; i * hLen < dkLen; i++) {
        blockIndex[0] = (i + 1) >>> 24;
        blockIndex[1] = (i + 1) >>> 16;
        blockIndex[2] = (i + 1) >>> 8;
        blockIndex[3] = (i + 1) >>> 0;
        
        // HMAC-SHA256(password, salt || blockIndex)
        const hmacData = new Uint8Array(salt.length + 4);
        hmacData.set(salt);
        hmacData.set(blockIndex, salt.length);
        
        const hash = HMAC_SHA256(password, hmacData);
        
        const copyLength = Math.min(hLen, dkLen - i * hLen);
        for (let j = 0; j < copyLength; j++) {
            T[i * hLen + j] = hash[j];
        }
    }
    
    return T.slice(0, dkLen);
}

function HMAC_SHA256(key, data) {
    const blockSize = 64;
    const outputSize = 32;
    
    // Key preprocessing
    if (key.length > blockSize) {
        key = SHA256(Array.from(key));
    }
    
    const keyPadded = new Uint8Array(blockSize);
    keyPadded.set(key);
    
    // Inner and outer padding
    const ipadKey = new Uint8Array(blockSize);
    const opadKey = new Uint8Array(blockSize);
    
    for (let i = 0; i < blockSize; i++) {
        ipadKey[i] = keyPadded[i] ^ 0x36;
        opadKey[i] = keyPadded[i] ^ 0x5c;
    }
    
    // Inner hash: SHA256(ipadKey || data)
    const innerData = new Uint8Array(blockSize + data.length);
    innerData.set(ipadKey);
    innerData.set(data, blockSize);
    const innerHash = SHA256(Array.from(innerData));
    
    // Outer hash: SHA256(opadKey || innerHash)
    const outerData = new Uint8Array(blockSize + outputSize);
    outerData.set(opadKey);
    outerData.set(innerHash, blockSize);
    return SHA256(Array.from(outerData));
}

// Core scrypt SMix function
function scryptROMix(B, r, N) {
    const X = new Uint32Array(32 * r);
    const V = new Uint32Array(32 * r * N);
    
    // Convert B to X
    for (let i = 0; i < 32 * r; i++) {
        X[i] = (B[i * 4] << 0) | (B[i * 4 + 1] << 8) | (B[i * 4 + 2] << 16) | (B[i * 4 + 3] << 24);
    }
    
    // SMix 1
    for (let i = 0; i < N; i++) {
        V.set(X, i * 32 * r);
        scryptBlockMix(X, r);
    }
    
    // SMix 2
    for (let i = 0; i < N; i++) {
        const j = integerify(X, r) & (N - 1);
        for (let k = 0; k < 32 * r; k++) {
            X[k] ^= V[j * 32 * r + k];
        }
        scryptBlockMix(X, r);
    }
    
    // Convert X back to B
    for (let i = 0; i < 32 * r; i++) {
        B[i * 4] = X[i] >>> 0;
        B[i * 4 + 1] = X[i] >>> 8;
        B[i * 4 + 2] = X[i] >>> 16;
        B[i * 4 + 3] = X[i] >>> 24;
    }
}

function scryptBlockMix(B, r) {
    const X = new Uint32Array(16);
    const Y = new Uint32Array(32 * r);
    
    // X = B[2r-1]
    X.set(B.subarray((2 * r - 1) * 16, 2 * r * 16));
    
    for (let i = 0; i < 2 * r; i++) {
        // X = salsa20_8(X XOR B[i])
        for (let j = 0; j < 16; j++) {
            X[j] ^= B[i * 16 + j];
        }
        salsa20_8(X);
        
        // Y[i] = X
        Y.set(X, i * 16);
    }
    
    // B = (Y[0], Y[2], ..., Y[2r-2], Y[1], Y[3], ..., Y[2r-1])
    for (let i = 0; i < r; i++) {
        B.set(Y.subarray(i * 2 * 16, (i * 2 + 1) * 16), i * 16);
        B.set(Y.subarray((i * 2 + 1) * 16, (i * 2 + 2) * 16), (r + i) * 16);
    }
}

function salsa20_8(B) {
    const x = new Uint32Array(16);
    x.set(B);
    
    for (let i = 0; i < 8; i += 2) {
        // Column rounds
        x[4] ^= rotl(x[0] + x[12], 7);  x[9] ^= rotl(x[5] + x[1], 7);
        x[14] ^= rotl(x[10] + x[6], 7); x[3] ^= rotl(x[15] + x[11], 7);
        
        x[8] ^= rotl(x[4] + x[0], 9);   x[13] ^= rotl(x[9] + x[5], 9);
        x[2] ^= rotl(x[14] + x[10], 9); x[7] ^= rotl(x[3] + x[15], 9);
        
        x[12] ^= rotl(x[8] + x[4], 13); x[1] ^= rotl(x[13] + x[9], 13);
        x[6] ^= rotl(x[2] + x[14], 13); x[11] ^= rotl(x[7] + x[3], 13);
        
        x[0] ^= rotl(x[12] + x[8], 18); x[5] ^= rotl(x[1] + x[13], 18);
        x[10] ^= rotl(x[6] + x[2], 18); x[15] ^= rotl(x[11] + x[7], 18);
        
        // Row rounds
        x[1] ^= rotl(x[0] + x[3], 7);   x[6] ^= rotl(x[5] + x[4], 7);
        x[11] ^= rotl(x[10] + x[9], 7); x[12] ^= rotl(x[15] + x[14], 7);
        
        x[2] ^= rotl(x[1] + x[0], 9);   x[7] ^= rotl(x[6] + x[5], 9);
        x[8] ^= rotl(x[11] + x[10], 9); x[13] ^= rotl(x[12] + x[15], 9);
        
        x[3] ^= rotl(x[2] + x[1], 13);  x[4] ^= rotl(x[7] + x[6], 13);
        x[9] ^= rotl(x[8] + x[11], 13); x[14] ^= rotl(x[13] + x[12], 13);
        
        x[0] ^= rotl(x[3] + x[2], 18);  x[5] ^= rotl(x[4] + x[7], 18);
        x[10] ^= rotl(x[9] + x[8], 18); x[15] ^= rotl(x[14] + x[13], 18);
    }
    
    for (let i = 0; i < 16; i++) {
        B[i] = (x[i] + B[i]) >>> 0;
    }
}

function rotl(x, n) {
    return ((x << n) | (x >>> (32 - n))) >>> 0;
}

function integerify(B, r) {
    return B[(2 * r - 1) * 16] >>> 0;
}

// Main scrypt function
function _scrypt(password, salt, N, r, p, dkLen, progressCallback) {
    // Validate parameters
    if (N === 0 || (N & (N - 1)) !== 0) throw Error("N must be a power of 2");
    if (r * p >= 1 << 30) throw Error("r*p must be < 2^30");
    if (dkLen > (1 << 32) - 1) throw Error("dkLen must be < 2^32");

    // Convert password and salt to Uint8Array
    if (typeof password === 'string') {
        password = new TextEncoder().encode(password);
    } else if (password instanceof Buffer) {
        password = new Uint8Array(password);
    }
    
    if (typeof salt === 'string') {
        salt = new TextEncoder().encode(salt);
    } else if (salt instanceof Buffer) {
        salt = new Uint8Array(salt);
    }

    // Phase 1: PBKDF2-HMAC-SHA256
    const B = PBKDF2_HMAC_SHA256_OneIter(password, salt, p * 128 * r);
    
    // Phase 2: SMix
    for (let i = 0; i < p; i++) {
        scryptROMix(B.subarray(i * 128 * r, (i + 1) * 128 * r), r, N);
        if (progressCallback) {
            progressCallback(null, (i + 1) / p);
        }
    }
    
    // Phase 3: PBKDF2-HMAC-SHA256
    const result = PBKDF2_HMAC_SHA256_OneIter(password, B, dkLen);
    
    return Array.from(result);
}

// Export the functions
function syncScrypt(password, salt, N, r, p, dkLen) {
    return new Uint8Array(_scrypt(password, salt, N, r, p, dkLen));
}

module.exports = {
    syncScrypt: syncScrypt,
    _scrypt: _scrypt
};