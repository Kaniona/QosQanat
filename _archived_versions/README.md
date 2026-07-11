# Archived previous QosQanat versions

The canonical project is this monorepo (`Documents/qosqanat`: Flutter `frontend/` +
Node.js `backend/`). On 2026-06-20 several older / parallel QosQanat project folders
that were scattered across the machine were consolidated: their **human-written source
code only** (lib/, test/, src/, configs, docs — no node_modules / build / binary assets)
was archived here, and the original heavy folders were deleted to reclaim ~7 GB.

These are NOT lost fragments of the monorepo — each was a complete, independently
architected version of the app. They are kept only as a safety net in case an old
screen/idea needs to be referenced. Do not expect them to compile against the monorepo.

| Archive | Origin (deleted) | What it was |
|---|---|---|
| qosqanat_2_0.tar.gz | Documents/qosqanat_2_0 | Direct predecessor; the monorepo `frontend/` was built from this |
| qosqanat_claude_code_flutter.tar.gz | Downloads/qosqanat_claude_code_flutter | Flutter version, same architecture family, finer-grained widget split |
| qosqanat_home_mobile.tar.gz | ~/qosqanat/mobile | Clean-architecture variant (domain/features/router) |
| QosQanatCP.tar.gz | Documents/QosQanatCP | Flutter variant with mini-games (pubspec: qos_qanat) |
| qosqanatMVP.tar.gz | Documents/qosqanatMVP | Early Firebase-based MVP |
| QosQanatFable.tar.gz | Documents/QosQanatFable | Node.js backend variant, own git history |
| QosQanatClaudeCode_RN.tar.gz | Documents/QosQanatClaudeCode | React Native implementation (different stack) |
| qosqanat_2_0_v1_backup_lib.tar.gz | Documents/qosqanat_2_0_v1_backup_lib | Loose lib/test backup of v1 |

To inspect one: `tar tzf <file>` to list, `tar xzf <file>` to extract.
