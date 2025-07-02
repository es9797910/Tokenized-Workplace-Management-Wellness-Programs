# Tokenized Workplace Management Wellness Programs

A blockchain-based wellness program management system that tokenizes employee participation and outcomes in workplace wellness initiatives.

## Overview

This system provides a comprehensive solution for managing workplace wellness programs through smart contracts, enabling transparent tracking of participation, health metrics, and outcomes while rewarding employees with tokens for their engagement.

## Features

### Core Contracts

1. **Wellness Coordinator Verification** (`wellness-coordinator.clar`)
    - Validates and manages wellness coordinators
    - Role-based access control
    - Coordinator certification tracking

2. **Program Management** (`program-management.clar`)
    - Creates and manages wellness programs
    - Program lifecycle management
    - Budget and resource allocation

3. **Participation Tracking** (`participation-tracking.clar`)
    - Tracks employee participation in programs
    - Attendance and engagement metrics
    - Participation rewards distribution

4. **Health Monitoring** (`health-monitoring.clar`)
    - Secure health metrics tracking
    - Privacy-preserving data storage
    - Health improvement tracking

5. **Outcome Measurement** (`outcome-measurement.clar`)
    - Measures program effectiveness
    - ROI calculations
    - Success metrics tracking

## Token Economics

- **Participation Tokens**: Earned through program participation
- **Achievement Tokens**: Awarded for reaching health milestones
- **Coordinator Tokens**: Distributed to certified coordinators
- **Outcome Tokens**: Bonus tokens for measurable health improvements

## Getting Started

### Prerequisites

- Clarity CLI
- Node.js 18+
- Vitest for testing

### Installation

```bash
git clone <repository-url>
cd tokenized-workplace-wellness
npm install
```

### Testing

```bash
npm test
```

### Deployment

```bash
# Deploy to testnet
clarinet deploy --testnet

# Deploy to mainnet
clarinet deploy --mainnet
```

## Contract Architecture

### Data Flow

1. **Coordinator Registration**: Wellness coordinators register and get verified
2. **Program Creation**: Coordinators create wellness programs
3. **Employee Enrollment**: Employees join programs
4. **Participation Tracking**: System tracks employee activities
5. **Health Monitoring**: Health metrics are recorded (privacy-preserved)
6. **Outcome Measurement**: Program effectiveness is measured
7. **Token Distribution**: Rewards are distributed based on participation and outcomes

### Security Features

- Multi-signature coordinator verification
- Privacy-preserving health data storage
- Role-based access control
- Audit trail for all transactions

## API Reference

### Wellness Coordinator Contract

- `register-coordinator(coordinator-info)`: Register new coordinator
- `verify-coordinator(coordinator-id)`: Verify coordinator credentials
- `revoke-coordinator(coordinator-id)`: Revoke coordinator access

### Program Management Contract

- `create-program(program-details)`: Create new wellness program
- `update-program(program-id, updates)`: Update program details
- `close-program(program-id)`: Close program enrollment

### Participation Tracking Contract

- `enroll-employee(program-id, employee-id)`: Enroll in program
- `record-participation(program-id, employee-id, activity)`: Record activity
- `claim-rewards(program-id, employee-id)`: Claim participation tokens

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For support and questions, please open an issue in the GitHub repository.
