-- Minimal runner for plugin `test.lua` files. Each collects cases, then calls
-- `t.done()`, which exits non-zero so the Nix check fails.
local M = { failures = 0, total = 0 }

function M.eq(name, expected, actual)
	M.total = M.total + 1
	if vim.deep_equal(expected, actual) then
		return
	end

	M.failures = M.failures + 1
	io.stderr:write(
		("FAIL %s\n  expected %s\n  actual   %s\n"):format(name, vim.inspect(expected), vim.inspect(actual))
	)
end

function M.done()
	io.stdout:write(("%d passed, %d failed\n"):format(M.total - M.failures, M.failures))
	os.exit(M.failures == 0 and 0 or 1)
end

return M
