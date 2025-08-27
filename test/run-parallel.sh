#!/bin/bash

# Test Runner Wrapper - Now just delegates to Make
# Kept for backward compatibility

# Default to 4 parallel jobs
JOBS=${PARALLEL_JOBS:-4}

# Pass through to Make
exec make -C "$(dirname "$0")" -j"$JOBS" "$@"