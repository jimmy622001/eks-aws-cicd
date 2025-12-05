# TISA File Testing Procedure
## TEST1 & TEST2 Process Validation

## Table of Contents
1. [Introduction](#introduction)
2. [Process Overview](#process-overview)
3. [Test Objectives](#test-objectives)
4. [Test Scope](#test-scope)
5. [Prerequisites](#prerequisites)
6. [Test Environment](#test-environment)
7. [Roles and Responsibilities](#roles-and-responsibilities)
8. [Test Scenarios](#test-scenarios)
9. [Test Execution Steps](#test-execution-steps)
10. [Success Criteria](#success-criteria)
11. [Reporting](#reporting)

## 1. Introduction

This document outlines the testing procedure for the TISA (Tax Incentivised Savings Association) file processing between TEST2 and Test1. It addresses the requirements specified in section 3.4.1 of the project documentation, focusing on validating the process of sharing and updating the ISA providers list within the integrated systems.

### 1.1 Background

TEST2 receives a file from TISA organization monthly/quarterly containing an up-to-date list of ISA providers. Currently, this file is used to update the UFSS system at TEST2. A new process needs to be established to share this file with the Managed Services Team at Test1 and ensure it is uploaded into Parity, keeping the customer-facing systems current.

### 1.2 Purpose

The purpose of this test is to:
1. Validate the complete process flow for TISA file handling between TEST2 and Test1
2. Confirm all responsible parties understand their roles in the process
3. Verify the mechanism for transferring the file information between organizations
4. Ensure the file is correctly uploaded and applied in the Parity system

## 2. Process Overview

The TISA file handling process involves several steps across both TEST2 and Test1 organizations:

1. **File Receipt**: TEST2 receives the TISA file containing ISA provider information
2. **UFSS Update**: TEST2 updates their UFSS system (existing process, not in test scope)
3. **File Transfer**: TEST2 transfers the file to Test1's Managed Services Team
4. **Service Request**: Appropriate documentation and service request creation
5. **Parity Update**: Test1 uploads the file into Parity system
6. **Validation**: Verification that the updated provider list is available to customers

## 3. Test Objectives

The primary objectives of this test are to:

1. Define and document the end-to-end process for TISA file handling
2. Identify the responsible parties at each step of the process
3. Establish the mechanism for transferring the file between organizations
4. Validate that the file is correctly processed and applied in all systems
5. Confirm that updated ISA provider information is available to customers

## 4. Test Scope

### 4.1 In Scope

- Receipt and initial processing of the TISA file at TEST2
- Identification of responsible parties at TEST2 for file handling
- Transfer mechanism between TEST2 and Test1
- Service request process documentation
- File upload process into Parity
- Validation of updated information availability

### 4.2 Out of Scope

- UFSS system update process (existing process)
- Internal TEST2 file distribution processes
- Technical integration details within Parity system
- End-user experience testing with the updated provider list

## 5. Prerequisites

Before conducting the test, the following prerequisites must be met:

1. A test TISA file with representative data is available
2. Access to relevant systems at TEST2 and Test1 is provisioned
3. Test environments are prepared and operational
4. Contact information for all responsible parties is documented
5. Service request templates are prepared
6. File transfer mechanisms are technically available

## 6. Test Environment

The test will be conducted in non-production environments:

1. **TEST2 Environment**:
   - Development or test instance of file handling systems
   - Test instance of any transfer mechanisms

2. **Test1 Environment**:
   - Test instance of service request system
   - Non-production Parity environment for file upload testing

## 7. Roles and Responsibilities

### 7.1 TEST2 Roles

| Role | Responsibility | Department |
|------|----------------|------------|
| TISA File Receiver | Designated person/team to receive TISA files from the organization | [To be defined] |
| File Transfer Coordinator | Responsible for initiating the transfer to Test1 | [To be defined] |
| Service Request Creator | Creates and documents the appropriate service request | [To be defined] |

### 7.2 Test1 Roles

| Role | Responsibility | Department |
|------|----------------|------------|
| Managed Services Team Member | Receives the TISA file from TEST2 | Managed Services |
| File Processor | Responsible for uploading the file into Parity | [To be defined] |
| System Validator | Verifies the file has been correctly applied | [To be defined] |

## 8. Test Scenarios

### 8.1 Standard Process Flow

Test the complete end-to-end process with all steps executing normally:
1. Receipt of TISA file
2. Transfer to Test1
3. Service request creation
4. Parity upload
5. Validation of successful update

### 8.2 Handling File Update Failures

Test recovery processes when the file cannot be properly uploaded:
1. Failed file upload in Parity
2. Error notification process
3. Resolution steps
4. Re-upload and verification

### 8.3 Handling Transfer Failures

Test recovery processes when the file transfer between organizations fails:
1. Failed transfer detection
2. Notification to responsible parties
3. Alternative transfer methods
4. Confirmation of successful transfer

## 9. Test Execution Steps

### 9.1 Preparation Phase

1. **Prepare Test Data**:
   - Create a test TISA file with representative data
   - Distribute file access information to test participants

2. **Document Baseline**:
   - Record the current state of ISA providers in test systems
   - Document existing processes for reference

3. **Conduct Pre-Test Briefing**:
   - Review test objectives and steps with all participants
   - Confirm roles and responsibilities
   - Address any questions or concerns

### 9.2 Execution Phase

#### 9.2.1 Standard Process Flow Testing

1. **File Receipt** (TEST2):
   - Simulate receipt of TISA file from the organization
   - Document the process and responsible party
   - Verify file handling procedures

2. **File Transfer** (TEST2 to Test1):
   - Execute the transfer process to Test1's Managed Services Team
   - Document the transfer mechanism used
   - Record transfer confirmation or acknowledgment

3. **Service Request** (TEST2):
   - Create appropriate service request documentation
   - Specify the process for logging the request (SNOW or alternative)
   - Ensure all required information is included

4. **File Processing** (Test1):
   - Managed Services Team receives the file
   - Execute the process to upload the file into Parity
   - Document each step and responsible party

5. **Validation** (Test1):
   - Verify the file has been correctly applied in Parity
   - Confirm ISA provider list is updated
   - Validate customer-facing views display correct information

#### 9.2.2 Exception Handling Testing

1. **Simulate Upload Failure**:
   - Force a failure during the Parity upload process
   - Document error handling and notification procedures
   - Execute recovery process
   - Verify successful resolution

2. **Simulate Transfer Failure**:
   - Force a failure during the file transfer between organizations
   - Document error detection and notification process
   - Execute alternative transfer procedure
   - Verify successful resolution

### 9.3 Documentation Phase

1. **Process Documentation**:
   - Document the complete process flow with responsible parties
   - Create process diagrams for visualization
   - Detail each step with specific actions

2. **Handover Documentation**:
   - Create handover documentation for operational teams
   - Include troubleshooting guidelines
   - Document contact information for escalations

## 10. Success Criteria

The test will be considered successful if:

1. **Process Definition**:
   - Clear identification of who is responsible to receive the file on TEST2 side
   - Documented mechanism for transferring the file to the Managed Service team
   - Defined responsibility for uploading the file into Parity

2. **Process Execution**:
   - Successful transfer of file from TEST2 to Test1
   - Proper service request creation with all required information
   - Successful upload of file into Parity system

3. **Validation**:
   - Confirmation that the system has been correctly updated
   - Updated ISA provider list is available to customers
   - Exception handling procedures are documented and validated

## 11. Reporting

### 11.1 Test Results Documentation

A comprehensive test report will be created, including:

1. **Process Definition**:
   - Detailed process flow with responsible parties
   - Transfer mechanism specifications
   - Service request templates

2. **Test Results**:
   - Success/failure status for each test scenario
   - Issues encountered and resolutions
   - Screenshots and evidence of process execution

3. **Recommendations**:
   - Process improvements
   - Automation opportunities
   - Documentation enhancements

### 11.2 Process Documentation

Final process documentation will be created, including:

1. **Process Flow Diagram**:
   - Visual representation of the complete process
   - Decision points and exception paths
   - System interactions

2. **Responsibility Matrix**:
   - Clear assignment of responsibilities by role
   - Contact information for each role
   - Escalation paths

3. **Operational Guide**:
   - Step-by-step instructions for each part of the process
   - Troubleshooting guidelines
   - Regular execution schedule