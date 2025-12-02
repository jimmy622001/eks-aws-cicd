Feature: S3 Bucket Security
  In order to have secure S3 buckets
  As engineers
  We'll enforce S3 security best practices

  Scenario: Ensure S3 buckets are encrypted
    Given I have aws_s3_bucket defined
    Then it must have server_side_encryption_configuration

  Scenario: Ensure S3 buckets are not publicly accessible
    Given I have aws_s3_bucket defined
    When I count them
    Then I expect result is greater than 0
    
    Given I have aws_s3_bucket defined
    Then it must have acl
    And its acl must not be public-read
    And its acl must not be public-read-write
    And its acl must not be authenticated-read
    
    Given I have aws_s3_bucket_public_access_block defined
    Then it must have block_public_acls
    And its block_public_acls must be true
    And it must have block_public_policy
    And its block_public_policy must be true
    And it must have ignore_public_acls
    And its ignore_public_acls must be true
    And it must have restrict_public_buckets
    And its restrict_public_buckets must be true

  Scenario: Ensure S3 buckets have versioning enabled
    Given I have aws_s3_bucket defined
    Then it must have versioning
    And its versioning must have enabled
    And its versioning.enabled must be true