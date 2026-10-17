# The shell entrypoint supplies its canonical fixture list. No cached target
# can skip a required compile or observer: every fixture is phony.
.PHONY: all $(FIXTURES)
all: $(FIXTURES)
	@bash "$$RUNTIME_SMOKE_ROOT/scripts/ci/runtime-smoke-otp-core.sh"
	@echo "[runtime-smoke] All runtime smoke tests passed ✅"

$(FIXTURES):
	@bash "$$RUNTIME_SMOKE_RUNNER" --fixture "$@"
