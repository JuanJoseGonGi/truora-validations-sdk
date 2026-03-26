#ifndef TRUORA_DETECTION_H
#define TRUORA_DETECTION_H

#include <stdint.h>

uint32_t td_bitmask_version(void);
uint32_t td_run_checks(uint32_t checks_mask);
const char* td_sign_report(
    const char* validation_id,
    const char* flow_type,
    uint32_t trust_score,
    uint32_t risk_bitmask,
    uint64_t timestamp
);
uint32_t td_get_escalation_threshold(void);
void td_free_string(const char* ptr);

#endif
