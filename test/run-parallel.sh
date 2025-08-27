#!/bin/bash

# Parallel Test Runner Wrapper
# Simple wrapper around make for better npm integration

# Default settings
JOBS=${PARALLEL_JOBS:-4}
MAKEFILE="test/Makefile.parallel"
MAKE_ARGS="-s"  # Silent mode for cleaner output

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -j|--jobs)
            JOBS="$2"
            shift 2
            ;;
        --verbose)
            MAKE_ARGS=""
            shift
            ;;
        test=*)
            TEST_NAME="${1#test=}"
            TARGETS="test-$TEST_NAME"
            shift
            ;;
        clean)
            TARGETS="clean"
            shift
            ;;
        help|--help)
            make -f "$MAKEFILE" help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Set default target if none specified
TARGETS=${TARGETS:-all}

# Show what we're doing
echo "🚀 Running tests with $JOBS parallel workers..."
echo ""

# Run make with parallel jobs
make -f "$MAKEFILE" -j"$JOBS" $MAKE_ARGS $TARGETS

# Exit with make's exit code
exit $?