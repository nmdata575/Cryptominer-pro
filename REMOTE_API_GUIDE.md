# Remote API Guide for CryptoMiner Pro

## Overview
CryptoMiner Pro now supports remote connectivity, allowing future Android apps and other remote clients to connect and control the mining system.

## Authentication
All remote devices must first register to obtain an access token.

### Register Device
```http
POST /api/remote/register
Content-Type: application/json

{
  "device_id": "unique_device_identifier",
  "device_name": "My Android Phone",
  "access_token": null
}
```

**Response:**
```json
{
  "success": true,
  "access_token": "secure_token_here",
  "device_id": "unique_device_identifier",
  "message": "Device registered successfully"
}
```

## Remote Mining Control

### Start Mining Remotely
```http
POST /api/remote/mining/start?device_id=your_device_id
Content-Type: application/json

{
  "coin": "litecoin",
  "mode": "pool",
  "threads": 4,
  "intensity": 0.8,
  "ai_enabled": true,
  "auto_optimize": true,
  "wallet_address": "your_wallet_address",
  "pool_username": "your_pool_username",
  "pool_password": "x"
}
```

### Stop Mining Remotely
```http
POST /api/remote/mining/stop?device_id=your_device_id
```

### Get Mining Status
```http
GET /api/remote/mining/status
```

**Response:**
```json
{
  "is_mining": true,
  "stats": {
    "hashrate": 1234.56,
    "accepted_shares": 10,
    "rejected_shares": 0,
    "blocks_found": 0,
    "uptime": 3600
  },
  "remote_access": true,
  "connected_devices": 2,
  "api_version": "1.0"
}
```

## Device Management

### Get Device Status
```http
GET /api/remote/status/{device_id}
```

### List All Devices
```http
GET /api/remote/devices
```

### Test Connection
```http
GET /api/remote/connection/test
```

## Android App Integration

### Setup Steps for Android Development
1. **Register Device**: Use the device's unique ID (Android ID or UUID)
2. **Store Token**: Securely store the access token locally
3. **Connect**: Use the token for all subsequent API calls
4. **Monitor**: Poll `/api/remote/mining/status` for real-time updates
5. **Control**: Use start/stop endpoints for mining control

### Example Android Implementation
```java
// Register device
String deviceId = Settings.Secure.getString(getContentResolver(), Settings.Secure.ANDROID_ID);
String deviceName = Build.MODEL + " - " + Build.MANUFACTURER;

// HTTP request to register
JSONObject registerRequest = new JSONObject();
registerRequest.put("device_id", deviceId);
registerRequest.put("device_name", deviceName);

// Send POST request to /api/remote/register
// Store returned access_token for future requests
```

## Security Features
- **Token-based Authentication**: Each device gets a unique access token
- **Device Tracking**: All registered devices are tracked with status
- **Secure Communication**: All API calls use HTTPS in production
- **Session Management**: Tokens can be revoked and renewed

## Real-time Updates
For real-time monitoring, Android apps can:
1. **WebSocket Connection**: Connect to `/api/ws` for live updates
2. **Polling**: Poll `/api/remote/mining/status` every 1-5 seconds
3. **Background Services**: Use Android background services for continuous monitoring

## Error Handling
All endpoints return standard HTTP status codes:
- `200`: Success
- `400`: Bad request (invalid parameters)
- `401`: Unauthorized (invalid token)
- `404`: Not found (device/resource not found)
- `500`: Internal server error

## Rate Limiting
- **Registration**: 10 requests per minute per IP
- **API Calls**: 100 requests per minute per device
- **WebSocket**: 1 connection per device

## Future Enhancements
- **Push Notifications**: Real-time alerts for mining events
- **Multi-user Support**: Multiple users can control the same miner
- **Remote Configuration**: Update miner settings remotely
- **Analytics**: Historical data and performance analytics
- **Backup/Restore**: Remote configuration backup and restore

## Testing
Use the test endpoint to verify connectivity:
```bash
curl -X GET "http://your-server/api/remote/connection/test"
```

This should return a success response with system information and available features.