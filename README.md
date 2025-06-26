# 🎓 Blockchain Certificate Issuer

A Clarity smart contract for issuing, managing, and verifying educational certificates as NFTs on the Stacks blockchain.

## 📋 Overview

This smart contract enables universities, bootcamps, and companies to issue tamper-proof certificates on-chain. Employers and other parties can instantly verify the authenticity of certificates without relying on centralized authorities.

## ✨ Features

- 🏛️ **Authorized Issuers**: Only pre-approved institutions can issue certificates
- 🎯 **NFT Certificates**: Each certificate is a unique non-fungible token
- 🔍 **Instant Verification**: Public verification using certificate hash or ID
- 📅 **Expiry Support**: Optional expiration dates for certificates
- 🚫 **Revocation**: Issuers can revoke certificates if needed
- 🔄 **Transferable**: Certificate holders can transfer ownership
- 📊 **Grade Tracking**: Optional grade information storage

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Installation

1. Clone this repository
2. Navigate to the project directory
3. Run `clarinet check` to verify the contract
4. Use `clarinet console` for interactive testing

## 📖 Usage

### For Contract Owner

#### Authorize an Institution
```clarity
(contract-call? .blockchain-certificate-issuer authorize-issuer 'SP1EXAMPLE... "Harvard University")
```

#### Revoke Institution Access
```clarity
(contract-call? .blockchain-certificate-issuer revoke-issuer 'SP1EXAMPLE...)
```

### For Authorized Issuers

#### Issue a Certificate
```clarity
(contract-call? .blockchain-certificate-issuer issue-certificate 
  'SP2STUDENT...  ; recipient
  "Computer Science Degree"  ; course name
  "MIT"  ; institution
  (some u1000000)  ; expiry block (optional)
  (some "A+")  ; grade (optional)
  "abc123def456..."  ; certificate hash
)
```

#### Revoke a Certificate
```clarity
(contract-call? .blockchain-certificate-issuer revoke-certificate u1)
```

### For Certificate Holders

#### Transfer Certificate
```clarity
(contract-call? .blockchain-certificate-issuer transfer-certificate u1 'SP3NEWOWNER...)
```

### For Verification (Read-Only)

#### Get Certificate Details
```clarity
(contract-call? .blockchain-certificate-issuer get-certificate u1)
```

#### Verify by Hash
```clarity
(contract-call? .blockchain-certificate-issuer verify-certificate-by-hash "abc123def456...")
```

#### Check if Certificate is Valid
```clarity
(contract-call? .blockchain-certificate-issuer is-certificate-valid u1)
```

#### Check Issuer Authorization
```clarity
(contract-call? .blockchain-certificate-issuer is-authorized-issuer 'SP1ISSUER...)
```

## 🔧 Contract Functions

### Public Functions
- `authorize-issuer` - Add new authorized certificate issuer
- `revoke-issuer` - Remove issuer authorization
- `issue-certificate` - Create new certificate NFT
- `revoke-certificate` - Mark certificate as revoked
- `transfer-certificate` - Transfer certificate ownership

### Read-Only Functions
- `get-certificate` - Retrieve certificate data
- `get-certificate-owner` - Get current certificate owner
- `verify-certificate-by-hash` - Verify certificate using hash
- `is-certificate-valid` - Check certificate validity
- `get-issuer-info` - Get issuer details
- `is-authorized-issuer` - Check if issuer is authorized
- `get-certificates-by-recipient` - Check recipient's certificates
- `get-certificates-by-issuer` - Check issuer's certificates
- `get-last-certificate-id` - Get latest certificate ID

## 🛡️ Security Features

- **Owner-only functions**: Critical functions restricted to contract owner
- **Issuer validation**: Only authorized issuers can create certificates
- **Hash uniqueness**: Prevents duplicate certificates
- **Revocation checks**: Ensures revoked certificates can't be used
- **Ownership verification**: Only certificate owners can transfer

## 📊 Data Structures

### Certificate Data
- Recipient address
- Issuer address
- Course name
- Institution name
- Issue date (block height)
- Optional expiry date
- Optional grade
- Certificate hash
- Revocation status

### Issuer Data
- Institution name
- Active status
- Authorization date

## 🧪 Testing

Use Clarinet console to test contract functions:

```bash
clarinet console
```

Example test sequence:
1. Authorize an issuer
2. Issue a certificate
3. Verify the certificate
4. Test revocation functionality

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is open source and available under the MIT License.

## 🆘 Support

For questions or issues, please open a GitHub issue or contact the development team.

---

Built with ❤️ using Clarity and Stacks blockchain technology
```

**Git Commit Message:**
```
feat: implement blockchain certificate issuer smart contract with NFT-based verification system
```

**GitHub Pull Request Title:**
```
🎓 Add Blockchain Certificate Issuer Smart Contract
```

**GitHub Pull Request Description:**
```
## Summary
Added a comprehensive blockchain certificate issuer smart contract that enables educational institutions to issue tamper-proof certificates as NFTs on the Stacks blockchain.

## What's Added
- **Smart Contract**: Complete Clarity implementation with 150+ lines
- **NFT System**: Certificates issued as unique non-fungible tokens
- **Authorization System**: Owner-controlled issuer management
- **Verification Features**: Public certificate verification by hash or ID
- **Transfer Capability**: Certificate holders can transfer ownership
- **Revocation System**: Issuers can revoke certificates when needed
- **Comprehensive README**: Detailed usage instructions and examples

## Key Features
✅ Authorized issuer management
✅ Certificate issuance with metadata (course, institution, grade, expiry)
✅ Public verification system
✅ Certificate revocation
✅ Ownership transfers
✅ Hash-based duplicate prevention
✅ Expiry date support

## Testing
- Contract passes Clarinet syntax validation
- All functions properly implemented with error handling
- Ready for deployment and testing

This implementation provides a solid foundation for educational certificate verification on blockchain.
