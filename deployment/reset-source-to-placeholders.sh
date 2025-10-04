#!/bin/bash

# Reset Source Files to Placeholders
# This script resets all source files back to placeholder values for clean deployments

echo "🔄 Resetting source files to placeholder values..."

# Reset API Gateway URLs
echo "📡 Resetting API Gateway URLs..."
sed -i "" "s|https://[a-z0-9]*\.execute-api\.[a-z0-9-]*\.amazonaws\.com/prod|API_GATEWAY_URL_PLACEHOLDER|g" source/index.html
sed -i "" "s|https://[a-z0-9]*\.execute-api\.[a-z0-9-]*\.amazonaws\.com/prod|API_GATEWAY_URL_PLACEHOLDER|g" source/3d-twin.html
sed -i "" "s|https://[a-z0-9]*\.execute-api\.[a-z0-9-]*\.amazonaws\.com/prod|API_GATEWAY_URL_PLACEHOLDER|g" source/tickets.html

# Reset AWS regions
echo "🌍 Resetting AWS regions..."
sed -i "" "s|region: 'us-east-1'|region: 'AWS_REGION_PLACEHOLDER'|g" source/index.html
sed -i "" "s|region: 'us-east-1'|region: 'AWS_REGION_PLACEHOLDER'|g" source/login.html
sed -i "" "s|region: 'us-east-1'|region: 'AWS_REGION_PLACEHOLDER'|g" source/auth.js

# Reset Cognito User Pool IDs
echo "🔧 Resetting Cognito User Pool IDs..."
sed -i "" "s|userPoolId: 'us-east-1_[A-Za-z0-9]*'|userPoolId: 'USER_POOL_ID_PLACEHOLDER'|g" source/auth.js
sed -i "" "s|userPoolId: 'us-east-1_[A-Za-z0-9]*'|userPoolId: 'USER_POOL_ID_PLACEHOLDER'|g" source/index.html
sed -i "" "s|userPoolId: 'us-east-1_[A-Za-z0-9]*'|userPoolId: 'USER_POOL_ID_PLACEHOLDER'|g" source/login.html

# Reset Cognito Client IDs
echo "🔑 Resetting Cognito Client IDs..."
sed -i "" "s|userPoolWebClientId: '[a-z0-9]*'|userPoolWebClientId: 'USER_POOL_CLIENT_ID_PLACEHOLDER'|g" source/auth.js
sed -i "" "s|userPoolWebClientId: '[a-z0-9]*'|userPoolWebClientId: 'USER_POOL_CLIENT_ID_PLACEHOLDER'|g" source/index.html
sed -i "" "s|userPoolWebClientId: '[a-z0-9]*'|userPoolWebClientId: 'USER_POOL_CLIENT_ID_PLACEHOLDER'|g" source/login.html

# Reset Identity Pool IDs
echo "🆔 Resetting Identity Pool IDs..."
sed -i "" "s|identityPoolId: 'us-east-1:[a-z0-9-]*'|identityPoolId: 'IDENTITY_POOL_ID_PLACEHOLDER'|g" source/auth.js

echo "✅ Source files reset to placeholder values"
echo "💡 Ready for clean deployment with ./deploy-loaddata.sh"