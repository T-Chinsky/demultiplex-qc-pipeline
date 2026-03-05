// Utility functions for BCL Convert pipeline

class Utils {
    /**
     * Check resource value against max limit
     * @param obj The resource value to check
     * @param type The type of resource ('memory', 'time', 'cpus')
     * @param params The params map containing max_* values
     * @return The constrained resource value
     */
    static check_max(obj, type, params) {
        if (type == 'memory') {
            try {
                if (obj.compareTo(params.max_memory as nextflow.util.MemoryUnit) == 1) {
                    return params.max_memory as nextflow.util.MemoryUnit
                } else {
                    return obj
                }
            } catch (all) {
                println "   ### ERROR ###   Max memory '${params.max_memory}' is not valid! Using default value: $obj"
                return obj
            }
        } else if (type == 'time') {
            try {
                if (obj.compareTo(params.max_time as nextflow.util.Duration) == 1) {
                    return params.max_time as nextflow.util.Duration
                } else {
                    return obj
                }
            } catch (all) {
                println "   ### ERROR ###   Max time '${params.max_time}' is not valid! Using default value: $obj"
                return obj
            }
        } else if (type == 'cpus') {
            try {
                return Math.min(obj as int, params.max_cpus as int)
            } catch (all) {
                println "   ### ERROR ###   Max cpus '${params.max_cpus}' is not valid! Using default value: $obj"
                return obj
            }
        }
    }
}
