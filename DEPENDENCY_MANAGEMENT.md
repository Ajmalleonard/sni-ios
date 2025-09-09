# Dependency Management Strategy

## Overview

This document outlines the dependency management strategy for the SNI Rentals iOS application. The project uses Swift Package Manager (SPM) with a consistent versioning approach to ensure stability and reproducible builds.

## Current Dependencies

### Core Dependencies

| Package | Current Version | Versioning Strategy | Purpose |
|---------|----------------|--------------------|---------|
| Firebase iOS SDK | 11.15.0 | `upToNextMajorVersion` | Authentication, Firestore, Core services |
| GoogleSignIn-iOS | 9.0.0 | `upToNextMajorVersion` | Google OAuth authentication |
| SocketIO Client Swift | 16.1.1 | `upToNextMajorVersion` | Real-time chat messaging |

### Transitive Dependencies

The following dependencies are automatically managed by SPM:
- Abseil C++ Binary (1.2024072200.0)
- App Check (11.2.0)
- AppAuth iOS (2.0.0)
- Google App Measurement (11.15.0)
- Google Data Transport (10.1.0)
- Google Utilities (8.1.0)
- gRPC Binary (1.69.0)
- GTM Session Fetcher (3.5.0)
- GTM App Auth (5.0.0)
- Interop iOS for Google SDKs (101.0.0)
- LevelDB (1.22.5)
- Nanopb (2.30910.0)
- Promises (2.4.0)
- Starscream (4.0.8)
- Swift Protobuf (1.30.0)

## Versioning Strategy

### Semantic Versioning

All dependencies follow semantic versioning (SemVer) principles:
- **Major version**: Breaking changes
- **Minor version**: New features, backward compatible
- **Patch version**: Bug fixes, backward compatible

### Version Constraints

**Primary Strategy: `upToNextMajorVersion`**
- Allows automatic updates for minor and patch versions
- Prevents breaking changes from major version updates
- Balances stability with security updates

**Example**: `minimumVersion: 11.15.0` with `upToNextMajorVersion` allows:
- ✅ 11.15.1, 11.16.0, 11.20.5
- ❌ 12.0.0 (requires manual review)

## Package Resolution

### Package.resolved File

- **Location**: `SNI Rentals.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- **Purpose**: Locks exact versions for reproducible builds
- **Version Control**: Committed to repository for team consistency
- **Updates**: Automatically updated when dependencies are resolved

### Gitignore Configuration

The root-level `Package.resolved` is gitignored, but the workspace-specific one is tracked:
```gitignore
# Package.resolved  # Root level ignored
# Workspace level is tracked for consistency
```

## Dependency Update Process

### Regular Updates

1. **Monthly Review**: Check for available updates
2. **Security Updates**: Apply immediately when available
3. **Testing**: Run full test suite after updates
4. **Documentation**: Update this file with version changes

### Major Version Updates

1. **Impact Assessment**: Review breaking changes
2. **Migration Planning**: Plan code changes if needed
3. **Testing**: Comprehensive testing in development
4. **Staged Rollout**: Deploy to staging before production

### Update Commands

```bash
# Check for available updates
xcodebuild -resolvePackageDependencies -project "SNI Rentals.xcodeproj"

# Update to latest compatible versions
# (Done through Xcode: File > Swift Packages > Update to Latest Package Versions)
```

## Best Practices

### Version Management

1. **Conservative Updates**: Prefer stability over latest features
2. **Batch Updates**: Group related dependency updates
3. **Change Tracking**: Document significant version changes
4. **Rollback Plan**: Keep previous working versions documented

### Security

1. **Vulnerability Monitoring**: Regular security audits
2. **Immediate Patching**: Apply security patches promptly
3. **Dependency Scanning**: Use automated tools when available

### Performance

1. **Bundle Size**: Monitor impact on app size
2. **Build Time**: Track compilation performance
3. **Runtime Impact**: Profile app performance after updates

## Troubleshooting

### Common Issues

1. **Build Failures**: Clean build folder and re-resolve packages
2. **Version Conflicts**: Check for incompatible dependency versions
3. **Missing Packages**: Verify network connectivity and repository access

### Resolution Steps

```bash
# Clean build folder
xcodebuild clean -project "SNI Rentals.xcodeproj"

# Reset package caches
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/org.swift.swiftpm

# Re-resolve packages
xcodebuild -resolvePackageDependencies -project "SNI Rentals.xcodeproj"
```

## Monitoring and Maintenance

### Regular Tasks

- [ ] Monthly dependency review
- [ ] Security vulnerability assessment
- [ ] Performance impact analysis
- [ ] Documentation updates

### Metrics to Track

- App bundle size changes
- Build time variations
- Runtime performance impact
- Security vulnerability count

## Contact

For questions about dependency management:
- Review this document first
- Check project issues for known problems
- Consult team lead for major version updates

---

**Last Updated**: January 2025  
**Next Review**: February 2025