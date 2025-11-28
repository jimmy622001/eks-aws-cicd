/**
 * Security scanner Lambda function
 * Runs security scans and reports findings
 */

exports.handler = async (event) => {
    console.log('Starting security scan for environment:', process.env.ENVIRONMENT);
    
    try {
        // Perform security checks
        const results = await performSecurityChecks();
        
        // Process results and generate report
        const report = generateReport(results);
        
        // Send notifications if issues found
        if (report.criticalIssuesCount > 0 || report.highIssuesCount > 0) {
            await sendNotifications(report);
        }
        
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Security scan completed successfully',
                reportSummary: {
                    criticalIssues: report.criticalIssuesCount,
                    highIssues: report.highIssuesCount,
                    mediumIssues: report.mediumIssuesCount,
                    lowIssues: report.lowIssuesCount
                }
            })
        };
    } catch (error) {
        console.error('Error during security scan:', error);
        
        return {
            statusCode: 500,
            body: JSON.stringify({
                message: 'Error during security scan',
                error: error.message
            })
        };
    }
};

/**
 * Perform security checks on infrastructure
 */
async function performSecurityChecks() {
    // This would be expanded with actual security checks
    const checks = [
        checkIAMPolicies(),
        checkSecurityGroups(),
        checkS3Buckets(),
        checkKMSKeys(),
        checkEKSSecurityConfig()
    ];
    
    const results = await Promise.all(checks);
    return results.flat();
}

/**
 * Generate a security report from findings
 */
function generateReport(results) {
    const criticalIssues = results.filter(r => r.severity === 'CRITICAL');
    const highIssues = results.filter(r => r.severity === 'HIGH');
    const mediumIssues = results.filter(r => r.severity === 'MEDIUM');
    const lowIssues = results.filter(r => r.severity === 'LOW');
    
    return {
        criticalIssuesCount: criticalIssues.length,
        highIssuesCount: highIssues.length,
        mediumIssuesCount: mediumIssues.length,
        lowIssuesCount: lowIssues.length,
        criticalIssues,
        highIssues,
        mediumIssues,
        lowIssues,
        timestamp: new Date().toISOString(),
        environment: process.env.ENVIRONMENT,
        region: process.env.REGION
    };
}

/**
 * Send notifications about security issues
 */
async function sendNotifications(report) {
    console.log('Sending notifications about security issues');
    // This would be implemented to send emails or other notifications
}

// Mock security check functions
async function checkIAMPolicies() {
    // In a real implementation, this would check IAM policies
    return [
        { 
            id: 'IAM001',
            resource: 'iam-policy-example',
            severity: 'MEDIUM',
            description: 'IAM policy with overly permissive access'
        }
    ];
}

async function checkSecurityGroups() {
    // In a real implementation, this would check security groups
    return [
        {
            id: 'SG001',
            resource: 'sg-example',
            severity: 'HIGH',
            description: 'Security group with open access to all IPs'
        }
    ];
}

async function checkS3Buckets() {
    // In a real implementation, this would check S3 bucket configurations
    return [
        {
            id: 'S3001',
            resource: 'example-bucket',
            severity: 'CRITICAL',
            description: 'S3 bucket with public access enabled'
        }
    ];
}

async function checkKMSKeys() {
    // In a real implementation, this would check KMS key configurations
    return [
        {
            id: 'KMS001',
            resource: 'key-example',
            severity: 'LOW',
            description: 'KMS key rotation not enabled'
        }
    ];
}

async function checkEKSSecurityConfig() {
    // In a real implementation, this would check EKS cluster security
    return [
        {
            id: 'EKS001',
            resource: process.env.PROJECT_NAME + '-eks-cluster',
            severity: 'MEDIUM',
            description: 'EKS cluster with public endpoint enabled'
        }
    ];
}