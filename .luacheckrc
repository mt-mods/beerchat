
std = "minetest+max"

-- Exclude regression tests / unit tests
exclude_files = {
	"**/spec/**",
}

globals = {
	"beerchat"
}

read_globals = {
	-- Deps
	"xban", "QoS"
}
