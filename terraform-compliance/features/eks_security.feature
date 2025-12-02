Feature: EKS Security Compliance
  In order to have secure EKS clusters
  As engineers
  We'll enforce security best practices

  Scenario: Ensure EKS Clusters are properly secured
    Given I have aws_eks_cluster defined
    Then it must have encryption_config
    And its encryption_config must have resources
    And its encryption_config.resources must include "secrets"
    And it must have logging
    And its logging must have enabled
    And its logging.enabled must include "api"
    And its logging.enabled must include "audit"
    And its logging.enabled must include "authenticator"

  Scenario: Ensure EKS clusters are not publicly accessible
    Given I have aws_eks_cluster defined
    When it has vpc_config
    Then it must have vpc_config.endpoint_private_access
    And its vpc_config.endpoint_private_access must be true
    And it must have vpc_config.endpoint_public_access
    And its vpc_config.endpoint_public_access must be false
    
  Scenario Outline: Ensure all data storage is encrypted
    Given I have <resource_name> defined
    When it has <attribute_name>
    Then it must have <encryption_property>
    
    Examples:
    | resource_name           | attribute_name  | encryption_property                      |
    | aws_ebs_volume          | size            | encrypted                               |
    | aws_s3_bucket           | bucket          | server_side_encryption_configuration    |
    | aws_rds_cluster         | engine          | storage_encrypted                       |
    | aws_dynamodb_table      | name            | server_side_encryption.enabled         |

  Scenario: Ensure security groups do not allow unrestricted access
    Given I have aws_security_group defined
    When it has ingress
    Then it must not have ingress
    With the property cidr_blocks
    Containing 0.0.0.0/0 and port 22
    
    Given I have aws_security_group defined
    When it has ingress
    Then it must not have ingress
    With the property cidr_blocks
    Containing 0.0.0.0/0 and port 3389

  Scenario: Ensure IAM roles follow least privilege
    Given I have aws_iam_role defined
    When it has assume_role_policy
    Then it must not have assume_role_policy containing "Action": "*"
    And it must not have assume_role_policy containing "Resource": "*"