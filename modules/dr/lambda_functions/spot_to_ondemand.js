'use strict';

const AWS = require('aws-sdk');

exports.handler = async (event) => {
  console.log('Failover event triggered:', JSON.stringify(event));
  
  const eks = new AWS.EKS({ region: process.env.REGION });
  const autoscaling = new AWS.AutoScaling({ region: process.env.REGION });
  const sns = new AWS.SNS({ region: process.env.REGION });
  
  try {
    // Step 1: Get EKS cluster details
    const clusterName = process.env.CLUSTER_NAME;
    const nodegroupName = process.env.NODE_GROUP_NAME;
    
    console.log(`Failover activated for cluster: ${clusterName}, nodegroup: ${nodegroupName}`);
    
    // Step 2: Get current nodegroup config
    const nodeGroupParams = {
      clusterName: clusterName,
      nodegroupName: nodegroupName
    };
    
    const nodeGroupData = await eks.describeNodegroup(nodeGroupParams).promise();
    const currentConfig = nodeGroupData.nodegroup;
    
    console.log('Current nodegroup configuration:', JSON.stringify(currentConfig, null, 2));
    
    // Step 3: Verify it's using SPOT instances
    if (currentConfig.capacityType !== 'SPOT') {
      console.log('Node group is already using ON_DEMAND capacity type. No action needed.');
      await sendAlert('Node group is already using ON_DEMAND capacity type. No action needed.');
      return {
        statusCode: 200,
        body: JSON.stringify('No action needed'),
      };
    }
    
    // Step 4: Update the node group to use ON_DEMAND instances
    const updateParams = {
      clusterName: clusterName,
      nodegroupName: nodegroupName,
      capacityType: 'ON_DEMAND'
    };
    
    // Add scaling config if needed
    if (process.env.SCALE_UP === 'true') {
      updateParams.scalingConfig = {
        desiredSize: parseInt(process.env.DESIRED_SIZE || 3),
        minSize: parseInt(process.env.MIN_SIZE || 2),
        maxSize: parseInt(process.env.MAX_SIZE || 5)
      };
    }
    
    console.log('Updating nodegroup to ON_DEMAND capacity type with parameters:', JSON.stringify(updateParams, null, 2));
    
    // Step 5: Apply the update
    await eks.updateNodegroupConfig(updateParams).promise();
    
    console.log('Successfully initiated update to ON_DEMAND capacity type');
    
    // Step 6: Send notification about the change
    await sendAlert('Successfully changed node group from SPOT to ON_DEMAND during failover');
    
    // Step 7: Scale up any autoscaling groups if needed
    if (process.env.AUTO_SCALE_GROUPS) {
      const asgNames = process.env.AUTO_SCALE_GROUPS.split(',');
      for (const asgName of asgNames) {
        const asgParams = {
          AutoScalingGroupName: asgName.trim(),
          DesiredCapacity: parseInt(process.env.ASG_DESIRED_SIZE || 3)
        };
        
        console.log(`Updating ASG ${asgName} to desired capacity: ${asgParams.DesiredCapacity}`);
        await autoscaling.setDesiredCapacity(asgParams).promise();
      }
    }
    
    return {
      statusCode: 200,
      body: JSON.stringify('Successfully updated to ON_DEMAND capacity type'),
    };
  } catch (error) {
    console.error('Error updating node group:', error);
    await sendAlert(`Error updating node group to ON_DEMAND: ${error.message}`);
    throw error;
  }
  
  // Helper function to send alerts
  async function sendAlert(message) {
    if (!process.env.SNS_TOPIC_ARN) {
      console.log('No SNS topic ARN provided for alerts');
      return;
    }
    
    const params = {
      Message: message,
      Subject: 'DR Failover - Capacity Type Update',
      TopicArn: process.env.SNS_TOPIC_ARN
    };
    
    await sns.publish(params).promise();
  }
};