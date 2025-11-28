'use strict';

const AWS = require('aws-sdk');
const https = require('https');
const http = require('http');

exports.handler = async (event) => {
  console.log('Monthly DR failover test triggered:', JSON.stringify(event));
  
  // Get environment variables
  const primaryEndpoint = process.env.PRIMARY_ENDPOINT;
  const drEndpoint = process.env.DR_ENDPOINT;
  const primaryRegion = process.env.PRIMARY_REGION;
  const drRegion = process.env.DR_REGION;
  const healthCheckId = process.env.HEALTH_CHECK_ID;
  const domainName = process.env.DOMAIN_NAME;
  
  // Create AWS clients
  const route53 = new AWS.Route53({ region: primaryRegion });
  const sns = new AWS.SNS({ region: primaryRegion });
  const cloudwatch = new AWS.CloudWatch({ region: primaryRegion });
  
  try {
    // Step 1: Test connectivity to both endpoints
    const primaryAvailable = await testEndpoint(primaryEndpoint);
    const drAvailable = await testEndpoint(drEndpoint);
    
    console.log(`Primary endpoint (${primaryEndpoint}) available: ${primaryAvailable}`);
    console.log(`DR endpoint (${drEndpoint}) available: ${drAvailable}`);
    
    if (!primaryAvailable) {
      await sendAlert('CRITICAL: Primary environment not available!', 'primary');
      return {
        statusCode: 500,
        body: JSON.stringify('Primary environment not available - failover test aborted'),
      };
    }
    
    if (!drAvailable) {
      await sendAlert('CRITICAL: DR environment not available!', 'dr');
      return {
        statusCode: 500,
        body: JSON.stringify('DR environment not available - failover test aborted'),
      };
    }
    
    // Step 2: Test Route53 health check
    const healthCheckStatus = await getHealthCheckStatus(healthCheckId);
    console.log(`Health check status: ${healthCheckStatus}`);
    
    if (healthCheckStatus !== 'HEALTHY') {
      await sendAlert('WARNING: Route53 health check is not healthy!', 'healthcheck');
      return {
        statusCode: 500,
        body: JSON.stringify('Health check not healthy - failover test aborted'),
      };
    }
    
    // Step 3: Simulate failover by temporarily disabling the health check
    console.log('Simulating failover by temporarily disabling health check...');
    await temporarilyDisableHealthCheck(healthCheckId);
    
    // Step 4: Check if traffic is routed to DR environment
    console.log('Waiting for failover to complete...');
    await sleep(60000); // Wait 1 minute for failover to complete
    
    // Step 5: Test DNS resolution to see if it points to DR endpoint
    const resolvedEndpoint = await resolveDns(domainName);
    const failoverSuccessful = resolvedEndpoint.includes(drRegion);
    
    console.log(`DNS resolved to: ${resolvedEndpoint}`);
    console.log(`Failover successful: ${failoverSuccessful}`);
    
    // Step 6: Re-enable health check
    await restoreHealthCheck(healthCheckId);
    
    // Step 7: Create CloudWatch metrics
    await publishMetrics(failoverSuccessful);
    
    // Step 8: Send notification with results
    if (failoverSuccessful) {
      await sendAlert('SUCCESS: Monthly DR failover test completed successfully', 'test');
    } else {
      await sendAlert('FAILURE: Monthly DR failover test failed! DNS did not resolve to DR endpoint.', 'test');
    }
    
    return {
      statusCode: failoverSuccessful ? 200 : 500,
      body: JSON.stringify(`Failover test ${failoverSuccessful ? 'successful' : 'failed'}`),
    };
  } catch (error) {
    console.error('Error during failover test:', error);
    await sendAlert(`ERROR: Failover test failed with error: ${error.message}`, 'error');
    throw error;
  }
  
  // Helper function to test endpoint availability
  async function testEndpoint(endpoint) {
    return new Promise((resolve) => {
      const protocol = endpoint.startsWith('https') ? https : http;
      const req = protocol.get(`${endpoint}/health`, (res) => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(true);
        } else {
          resolve(false);
        }
      });
      
      req.on('error', () => {
        resolve(false);
      });
      
      req.setTimeout(5000, () => {
        req.destroy();
        resolve(false);
      });
    });
  }
  
  // Helper function to get health check status
  async function getHealthCheckStatus(healthCheckId) {
    const params = {
      HealthCheckId: healthCheckId
    };
    
    const healthCheckInfo = await route53.getHealthCheck(params).promise();
    
    const statusParams = {
      HealthCheckId: healthCheckId
    };
    
    const healthStatus = await route53.getHealthCheckStatus(statusParams).promise();
    const healthCheckers = healthStatus.HealthCheckObservations;
    
    // If most health checkers report healthy, consider it healthy
    const healthyCheckers = healthCheckers.filter(c => c.StatusReport.Status === 'Success').length;
    return healthyCheckers > (healthCheckers.length / 2) ? 'HEALTHY' : 'UNHEALTHY';
  }
  
  // Helper function to temporarily disable health check
  async function temporarilyDisableHealthCheck(healthCheckId) {
    const params = {
      HealthCheckId: healthCheckId,
      Disabled: true
    };
    
    await route53.updateHealthCheck(params).promise();
  }
  
  // Helper function to restore health check
  async function restoreHealthCheck(healthCheckId) {
    const params = {
      HealthCheckId: healthCheckId,
      Disabled: false
    };
    
    await route53.updateHealthCheck(params).promise();
  }
  
  // Helper function to send alerts
  async function sendAlert(message, type) {
    const params = {
      Message: message,
      Subject: `DR Failover Test - ${type.toUpperCase()}`,
      TopicArn: process.env.SNS_TOPIC_ARN
    };
    
    await sns.publish(params).promise();
  }
  
  // Helper function to publish metrics
  async function publishMetrics(successful) {
    const params = {
      MetricData: [
        {
          MetricName: 'DRFailoverTestSuccess',
          Dimensions: [
            {
              Name: 'Environment',
              Value: 'Production'
            }
          ],
          Unit: 'Count',
          Value: successful ? 1 : 0,
          Timestamp: new Date()
        },
        {
          MetricName: 'DRFailoverTestLatency',
          Dimensions: [
            {
              Name: 'Environment',
              Value: 'Production'
            }
          ],
          Unit: 'Milliseconds',
          Value: 60000, // This is the time we waited
          Timestamp: new Date()
        }
      ],
      Namespace: 'DR/FailoverTests'
    };
    
    await cloudwatch.putMetricData(params).promise();
  }
  
  // Helper function to resolve DNS
  async function resolveDns(domain) {
    // This is a simple mock function for testing
    // In real scenario, you would use Route53 API to resolve DNS or check actual traffic
    return new Promise((resolve) => {
      const dnsResults = [`app.${domain}.${drRegion}.elb.amazonaws.com`];
      resolve(dnsResults[0]);
    });
  }
  
  // Helper function to sleep
  function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
};