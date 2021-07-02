local http = beerchat.http

minetest.register_chatcommand("beerchat_proxy_shutdown", {
    description = "triggers a shutdown in the beerchat-proxy app",
    privs = { server = true },
    func = function()
        http.fetch({
            url = beerchat.url .. "/shutdown",
            extra_headers = { "Content-Type: application/json" },
            timeout = 5,
            method = "POST"
        }, function()
            -- ignore errors
        end)
    end
})
