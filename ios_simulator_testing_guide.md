# iOS Simulator Testing Guide - Network Connectivity

## Quick Setup

### 1. Add Dependencies
Run this command to install the new logger dependency:
```bash
flutter pub get
```

### 2. Add Debug Access to Your App
Add this to your main navigation or settings screen:

```dart
import 'package:flutter/material.dart';
import 'screens/debug_menu_screen.dart';

// Add this button/tile somewhere in your app for easy access
ListTile(
  leading: Icon(Icons.bug_report),
  title: Text('Network Debug'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => DebugMenuScreen()),
  ),
),
```

### 3. Initialize Network Services
In your app's initialization (usually in `main.dart` or your main service initialization):

```dart
import 'lib/services/network/network_health_monitor.dart';
import 'lib/utils/ios_network_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable verbose logging for testing
  IOSNetworkLogger.setVerboseLogging(true);
  
  // Initialize network monitoring
  final healthMonitor = NetworkHealthMonitor();
  await healthMonitor.initialize();
  
  runApp(MyApp());
}
```

## Testing Scenarios in iOS Simulator

### Scenario 1: Basic Connectivity Test
1. **Setup**: Normal WiFi connection
2. **Test**: Open Debug Menu → Network Testing Screen → "API Connection Test"
3. **Expected**: ✅ Success with connection details
4. **Logs**: Check Xcode console for detailed request/response logs

### Scenario 2: DNS Resolution Test
1. **Setup**: Normal WiFi connection  
2. **Test**: "DNS Resolution Test"
3. **Expected**: ✅ Success with resolved IP addresses
4. **Logs**: DNS resolution timing and addresses logged

### Scenario 3: Simulate Poor Network Conditions
1. **Setup**: 
   - iOS Simulator → Settings → Developer → Network Link Conditioner
   - Enable "Very Bad Network" profile
2. **Test**: Run "Comprehensive Test Suite"
3. **Expected**: Tests should succeed but with longer response times
4. **Logs**: Timeout warnings and retry attempts logged

### Scenario 4: Simulate No Internet
1. **Setup**:
   - iOS Simulator → Settings → WiFi → Turn OFF WiFi
   - Or use Network Link Conditioner "100% Loss"
2. **Test**: Run any network test
3. **Expected**: ❌ Network errors with user-friendly messages
4. **Logs**: DNS failure (errno 8) and offline detection logged

### Scenario 5: Simulate DNS Failures
1. **Setup**: Use "Lossy Network" profile in Network Link Conditioner
2. **Test**: "DNS Resolution Test" 
3. **Expected**: May fail with DNS-specific errors
4. **Logs**: errno 8 detection and recovery attempts

### Scenario 6: Test Provider Recovery
1. **Setup**: Normal connection
2. **Test**: "Provider Recovery Test"
3. **Expected**: ✅ Simulated failure handling and recovery
4. **Logs**: Provider switching events and recovery statistics

### Scenario 7: Test Error Handling
1. **Setup**: Any connection
2. **Test**: "Error Handling Test"
3. **Expected**: ✅ All error types properly categorized
4. **Logs**: Different error types (DNS, timeout, HTTP) handled correctly

## iOS Console Monitoring

### View Logs in Xcode Console
1. Open Xcode
2. Window → Devices and Simulators
3. Select your simulator
4. Click "Open Console"
5. Filter by "SpiralJournal.Network" to see only network logs

### Expected Log Examples

**Successful DNS Resolution:**
```
✅ DNS Resolution Success - api.anthropic.com
   Resolution Time: 45ms
   Resolved Addresses:
     104.18.4.82 (ipv4)
     104.18.5.82 (ipv4)
```

**DNS Failure (errno 8):**
```
🔴 DNS Resolution Failed - api.anthropic.com
   Error: SocketException: Failed host lookup: 'api.anthropic.com'
   ⚠️  DNS Resolution Failure (errno 8) - Common iOS connectivity issue
   💡 Suggestions:
      - Check internet connectivity
      - Verify DNS settings
      - Try switching between WiFi/Cellular
```

**Network Request with Retry:**
```
🌐 Network Request - claude_api_request
   Method: POST
   URL: https://api.anthropic.com/v1/messages
   Timeout: 30s

🔄 Retry Attempt - claude_api_request
   Attempt: 2/3
   Delay: 4000ms
   Reason: DNS resolution failure

✅ Network Response - claude_api_request
   Method: POST
   Status: 200
   Response Time: 1250ms
```

## Testing Network Conditions

### Using Network Link Conditioner
Access via: **iOS Simulator → Settings → Developer → Network Link Conditioner**

**Recommended Profiles for Testing:**
- **3G**: Test slower connections
- **Very Bad Network**: Simulate poor conditions
- **100% Loss**: Test offline scenarios
- **Lossy Network**: Test intermittent failures

### Custom Network Profiles
Create custom profiles to test specific scenarios:
1. **DNS Failure Simulation**: High packet loss on DNS queries
2. **Slow API**: High latency to simulate slow API responses
3. **Intermittent Connection**: Periodic connection drops

## Manual Testing Checklist

### ✅ Basic Functionality
- [ ] App initializes without network errors
- [ ] Network status indicator shows correct state
- [ ] API calls complete successfully on good connection

### ✅ Error Handling
- [ ] DNS failures show user-friendly messages
- [ ] Timeouts trigger retry logic
- [ ] Offline state detected correctly
- [ ] Provider switches to fallback when needed

### ✅ Recovery Scenarios
- [ ] App recovers when network returns
- [ ] Provider switches back to primary when healthy
- [ ] Queued requests process when online
- [ ] No duplicate requests after recovery

### ✅ User Experience
- [ ] Error messages are clear and actionable
- [ ] Retry buttons work correctly
- [ ] Loading states shown during operations
- [ ] No app crashes on network errors

## Advanced Testing

### Test Real Device vs Simulator
Some networking behaviors differ between simulator and device:

**Simulator Limitations:**
- May not perfectly simulate cellular behavior
- DNS caching differences
- Different network stack behavior

**Device Testing:**
- Test on actual cellular networks
- Test in areas with poor reception
- Test airplane mode scenarios

### Performance Testing
Monitor these metrics during testing:

**Response Times:**
- DNS resolution: < 100ms (good), > 500ms (poor)
- API calls: < 2s (good), > 5s (timeout)
- Recovery time: < 30s after network restoration

**Resource Usage:**
- Memory usage during network operations
- Battery impact of retry logic
- CPU usage during error handling

## Debugging Common Issues

### Issue: Tests Always Pass
**Problem**: Network conditions too good to trigger errors
**Solution**: Use Network Link Conditioner with loss profiles

### Issue: No Logs Appearing
**Problem**: Logging not enabled or filtered incorrectly
**Solution**: 
- Enable verbose logging: `IOSNetworkLogger.setVerboseLogging(true)`
- Check Xcode console filter settings
- Ensure iOS deployment target supports logging

### Issue: Real API Key Required
**Problem**: Some tests need actual API key
**Solution**: 
- Use environment variables or config files
- Mock API responses for testing
- Use test endpoints when available

### Issue: Simulator Network Different from Device
**Problem**: Simulator networking doesn't match real device
**Solution**:
- Test on physical device
- Use cellular connection on device
- Test in various physical locations

## Production Testing Checklist

Before deploying to production:

- [ ] All tests pass on simulator
- [ ] All tests pass on physical device
- [ ] Error messages are user-friendly
- [ ] No API keys in logs
- [ ] Recovery timing is appropriate
- [ ] App Store compliance verified
- [ ] Performance impact acceptable
- [ ] Crash-free operation confirmed

## Automated Testing Integration

Consider adding these tests to your CI/CD pipeline:

```dart
// Example test cases
testWidgets('Network error widget displays correctly', (tester) async {
  final error = NetworkException(
    'Test DNS failure',
    type: NetworkErrorType.dnsFailure,
    isRetryable: true,
    originalError: null,
    errno: 8,
  );
  
  await tester.pumpWidget(NetworkErrorWidget(error: error));
  
  expect(find.text('Unable to connect'), findsOneWidget);
  expect(find.byIcon(CupertinoIcons.wifi_exclamationmark), findsOneWidget);
});
```

This testing guide ensures comprehensive validation of your iOS networking improvements before production deployment.