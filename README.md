# Digital Court Case Scheduling System

A comprehensive blockchain-based court case management system built with Clarity smart contracts for the Stacks blockchain.

## Overview

This system provides a decentralized solution for managing court proceedings, from initial case filing to final sentencing. It ensures transparency, immutability, and efficient coordination of all court-related activities.

## System Architecture

The system consists of five interconnected smart contracts:

### 1. Hearing Coordination Contract (`hearing-coordination.clar`)
- Manages courtroom availability and scheduling
- Assigns judges to cases based on availability and specialization
- Tracks hearing dates, times, and locations
- Handles rescheduling requests and conflicts

### 2. Attorney Notification Contract (`attorney-notification.clar`)
- Manages attorney registration and case assignments
- Sends automated notifications for schedule changes
- Tracks attorney availability and case load
- Maintains communication logs for audit purposes

### 3. Jury Selection Contract (`jury-selection.clar`)
- Coordinates juror summoning for trial cases
- Manages juror pool and availability
- Handles jury selection process and assignments
- Tracks juror compensation and attendance

### 4. Evidence Tracking Contract (`evidence-tracking.clar`)
- Manages exhibit submission and digital evidence
- Maintains chain of custody records
- Tracks evidence authentication and integrity
- Handles evidence access permissions

### 5. Sentencing Calculation Contract (`sentencing-calculation.clar`)
- Determines penalties based on legal guidelines
- Calculates sentences using predefined algorithms
- Tracks sentencing history and precedents
- Manages appeals and sentence modifications

## Key Features

- **Transparency**: All court proceedings are recorded on the blockchain
- **Immutability**: Case records cannot be tampered with once recorded
- **Efficiency**: Automated scheduling and notification systems
- **Accountability**: Complete audit trail for all actions
- **Security**: Cryptographic protection of sensitive information

## Data Structures

### Case Management
- Case ID generation and tracking
- Case status management (filed, scheduled, in-progress, completed)
- Participant role assignments (judge, attorney, defendant, plaintiff)

### Scheduling System
- Courtroom resource management
- Time slot allocation and conflict resolution
- Multi-party availability coordination

### Notification System
- Event-driven notifications
- Stakeholder communication tracking
- Deadline and reminder management

## Security Considerations

- Role-based access control for different user types
- Input validation and error handling
- Protection against common smart contract vulnerabilities
- Audit logging for all critical operations

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Basic understanding of Clarity smart contracts

### Installation
1. Clone the repository
2. Install dependencies: `npm install`
3. Run tests: `npm test`
4. Deploy contracts: `clarinet deploy`

### Testing
The system includes comprehensive test suites for each contract:
- Unit tests for individual functions
- Integration tests for contract interactions
- Edge case and error condition testing

## Usage Examples

### Scheduling a Hearing
```clarity
(contract-call? .hearing-coordination schedule-hearing 
  case-id 
  courtroom-id 
  judge-id 
  hearing-date 
  hearing-time)
