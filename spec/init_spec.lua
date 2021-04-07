require("mineunit")

mineunit("core")

describe("Mod initialization", function()

	it("Wont crash", function()
		sourcefile("init")
	end)

end)
