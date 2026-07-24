# Maintenance

This document outlines the maintenance policies of the *dlang-dockerized* project.

> [!CAUTION]
> Keep in mind, this is work done by volunteers.

- Maintenance is limited to fixing compatibility issues of the packaging scripts with the corresponding software.
- The provided *End of Life* (EOL) dates are non-binding estimations and subject to change without prior notice.
- The provided maintenance timeslines are a voluntary and non-committal promise.
- These terms are subject to change without prior notice.


## Coverage

### Base images

| Image            | Version       | EOL Compat | EOL Pkging |
| :--------------- | :------------ | ---------: | ---------: |
| docker.io/debian | bookworm-slim | 2027-06-30 | 2026-07-31 |
| docker.io/debian | trixie-slim   | 2028-08-31 |      *TBD* |

### Software

| Image  |     Branch |             EOL | Reason                                                                       |
| :----- | ---------: | --------------: | :--------------------------------------------------------------------------- |
| LDC    |      v0.17 |           *TBD* | Bootstrapping                                                                |
| LDC    | ~ltsmaster |           *TBD* | Bootstrapping                                                                |
| LDC    |      v1.20 |           *TBD* | Bootstrapping                                                                |
| LDC    |      v1.28 |      2027-05-31 | Practical relevance: Ubuntu 22.04 LTS (“Jammy Jellyfish”)                    |
| LDC    |      v1.30 |      2028-06-30 | Practical relevance: Debian 12 (“Bookworm”)                                  |
| LDC    |      v1.36 |      2029-05-31 | Practical relevance: Ubuntu 24.04 LTS (“Noble Numbat”)                       |
| LDC    |      v1.40 |      2030-06-30 | Practical relevance: Debian 13 (“Trixie”)                                    |
| LDC    |      v1.41 |      2031-05-31 | Practical relevance: Ubuntu 26.04 LTS (“Resolute Raccoon”)                   |
| LDC    |      v1.42 |      2027-03-31 | Courtesy of @0xEAB                                                           |
| DMD    |     v2.090 |      2026-12-31 | Courtesy of @0xEAB                                                           |
| DMD    |     v2.100 |      2026-12-31 | Courtesy of @0xEAB                                                           |
| DMD    |     v2.110 |      2026-12-31 | Courtesy of @0xEAB                                                           |
| DMD    |     v2.111 |      2027-03-31 | Courtesy of @0xEAB                                                           |
| DMD    |     v2.112 |      2027-12-31 | Courtesy of @0xEAB                                                           |
