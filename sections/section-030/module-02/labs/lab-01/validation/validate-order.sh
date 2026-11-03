#!/usr/bin/env bash
# PASS when infrastructure-configs depends on infrastructure-controllers and
# apps still depends on infrastructure-configs.
set -uo pipefail

CFG="$(kubectl -n flux-system get kustomization infrastructure-configs -o jsonpath='{.spec.dependsOn[*].name}' 2>/dev/null)"
APP="$(kubectl -n flux-system get kustomization apps -o jsonpath='{.spec.dependsOn[*].name}' 2>/dev/null)"
case " $CFG " in *" infrastructure-controllers "*) ;; *) echo "FAIL: infrastructure-configs does not depend on infrastructure-controllers (dependsOn: '$CFG')."; exit 1 ;; esac
case " $APP " in *" infrastructure-configs "*) ;; *) echo "FAIL: apps no longer depends on infrastructure-configs (dependsOn: '$APP')."; exit 1 ;; esac
echo "PASS: controllers, then configuration, then apps."
exit 0
