# Daily Journal System with Built-in Claude API

## Overview

The Spiral Journal app has been updated with a new daily journal system that uses a built-in Claude API key for automatic processing. This eliminates the need for users to manage their own API keys while providing a sustainable business model.

## Key Features

### 1. **Daily Journal Model**
- **One journal per day**: Users can continuously write throughout the day
- **Auto-save**: Content saves automatically every 3 seconds
- **No submit button**: Seamless writing experience
- **Midnight processing**: AI analysis happens automatically at midnight

### 2. **Built-in API Integration**
- **Environment variable API key**: Secure API key management via build-time variables
- **Usage tracking**: Monitors API calls and costs per user
- **Monthly limits**: 30 journal analyses per month per user
- **Graceful fallback**: Local analysis when API unavailable or limits exceeded

### 3. **Cost-Effective Business Model**
- **Predictable costs**: Maximum 1 API call per user per day
- **Low monthly cost**: ~$0.03-0.05 per user per month
- **Subscription ready**: Built for $1.99-2.99/month pricing
- **Usage analytics**: Track costs and user engagement

## Architecture

### Core Services

1. **DailyJournalService**: Manages continuous auto-saving
2. **DailyJournalProcessor**: Handles midnight AI processing
3. **UsageTrackingService**: Monitors API usage and enforces limits
4. **EnvironmentConfig**: Manages built-in API key configuration

### Database Schema

```sql
-- Daily journals (one per day)
CREATE TABLE daily_journals (
  id TEXT PRIMARY KEY,
  date TEXT NOT NULL UNIQUE,
  content TEXT DEFAULT '',
  moods TEXT DEFAULT '[]',
  is_processed INTEGER DEFAULT 0,
  processed_at TEXT,
  ai_analysis TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- Usage tracking
CREATE TABLE monthly_usage (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  month_year TEXT NOT NULL UNIQUE,
  processed_journals INTEGER DEFAULT 0,
  api_calls INTEGER DEFAULT 0,
  tokens_used INTEGER DEFAULT 0,
  cost_estimate REAL DEFAULT 0.0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

## Building with API Key

### Development Build
```bash
flutter build ios --dart-define=CLAUDE_API_KEY=sk-ant-your-dev-key-here
```

### Production Build
```bash
flutter build ios --release --dart-define=CLAUDE_API_KEY=sk-ant-your-prod-key-here
```

### TestFlight Build
Update your build script to include the API key:
```bash
cd ios
CLAUDE_API_KEY=sk-ant-your-prod-key-here ./testflight_build.sh
```

Or modify `ios/testflight_build.sh` to include:
```bash
flutter build ios --release --dart-define=CLAUDE_API_KEY=$CLAUDE_API_KEY
```

## User Experience Flow

### Daily Usage
1. **Morning**: User opens app, sees today's journal (blank or existing)
2. **Throughout day**: User writes and adds moods, content auto-saves
3. **Midnight**: Automatic AI processing happens in background
4. **Next morning**: User sees insights from yesterday's journal

### Monthly Limits
- **First 30 days**: Full Claude AI analysis
- **After 30 days**: Graceful fallback to local analysis
- **User notification**: "You've used your monthly AI analysis limit"
- **Future**: Option to upgrade to premium subscription

## API Usage & Costs

### Current Limits
- **30 analyses per month** per user
- **Claude 3 Haiku model** for cost efficiency
- **~500 input + 200 output tokens** per analysis
- **Estimated cost**: $0.03-0.05 per user per month

### Cost Breakdown
```
Input tokens: 500 × $0.25/1M = $0.000125
Output tokens: 200 × $1.25/1M = $0.00025
Total per analysis: ~$0.000375
Monthly per user: $0.000375 × 30 = $0.01125
```

### Business Model
- **Recommended subscription**: $1.99-2.99/month
- **Profit margin**: 177-266x markup
- **Break-even**: ~1 user per $60 in monthly revenue

## Security Considerations

### API Key Security
- ✅ Never committed to version control
- ✅ Build-time environment variables only
- ✅ Different keys for dev/staging/prod
- ✅ Key rotation capability
- ✅ Usage monitoring and alerts

### Data Privacy
- ✅ All journal data stored locally
- ✅ API calls only for analysis (no data retention by Claude)
- ✅ User controls their data completely
- ✅ Secure deletion capabilities

## Monitoring & Analytics

### Usage Tracking
- Monthly API call counts
- Token usage and costs
- Processing success/failure rates
- User engagement metrics

### Business Insights
- Cost per user trends
- Usage pattern analysis
- Subscription conversion opportunities
- Feature usage statistics

## Deployment Checklist

### Before Release
- [ ] Set production Claude API key
- [ ] Test API key in staging environment
- [ ] Verify usage tracking works
- [ ] Test monthly limit enforcement
- [ ] Confirm fallback analysis works
- [ ] Update build scripts with API key

### Monitoring Setup
- [ ] Set up API cost alerts
- [ ] Monitor usage patterns
- [ ] Track processing success rates
- [ ] Set up error logging
- [ ] Monitor user feedback

## Future Enhancements

### Subscription Integration
- In-app purchase setup
- Premium tier with higher limits
- Subscription status checking
- Usage limit adjustments

### Advanced Features
- Weekly/monthly insights
- Trend analysis
- Goal setting and tracking
- Social features (optional)

## Testing

### Manual Testing
1. Write journal entries throughout the day
2. Verify auto-save functionality
3. Test mood selection
4. Simulate midnight processing
5. Check usage limit enforcement
6. Verify fallback analysis

### API Testing
```bash
# Test with your API key
flutter test test/services/daily_journal_processor_test.dart
```

## Support

For questions about the daily journal system:
- Technical issues: Check error logs in `UsageTrackingService`
- API problems: Monitor Claude API status
- Cost concerns: Review usage analytics
- User feedback: Collect via TestFlight feedback

---

This system provides a seamless user experience while maintaining cost control and preparing for a sustainable subscription business model.
