# Changelog

VCF 9 in a box: All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 11-6-2025

### Added
```
├── .gitignore
├── CHANGELOG.md
├── config
│   ├── chekhovdns01
│   │   ├── 50-cloud-init.yaml
│   │   └── unbound01.conf
│   ├── chekhovdns02
│   │   ├── 50-cloud-init.yaml
│   │   └── unbound02.conf
│   ├── vcf90-two-node-bryan.json
├── LICENSE.md
```
### Changed

- Removed all passwords from all files - do a Find for "" and Replace with "PASSWORDYOUWANT" as needed. Must be 15 characters with symbols and caps.
- README.md - Updated to ensure proper credit (William Lam).
- ks-esx01.cfg - Updated to reflect my variables in my esx01.
- ks-esx02.cfg - Updated to reflect my variables in my esx02.

### Removed

### Fixed