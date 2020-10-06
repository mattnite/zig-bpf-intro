const std = @import("std");
const os = std.os;
const fd_t = os.fd_t;

const c = @cImport({
    @cInclude("linux/if_ether.h");
    @cInclude("net/if.h");
    @cInclude("linux/if_packet.h");
    @cInclude("arpa/inet.h");
});

pub const iphdr = packed struct {
    ihl: u4,
    version: u4,
    tos: u8,
    tot_len: u16,
    id: u16,
    frag_off: u16,
    ttl: u8,
    protocol: u8,
    check: u16,
    saddr: u32,
    daddr: u32,
};

pub fn create_raw_socket(net_if: []const u8) !fd_t {
    const ret = try os.socket(
        c.PF_PACKET,
        c.SOCK_RAW | c.SOCK_NONBLOCK | c.SOCK_CLOEXEC,
        c.htons(c.ETH_P_ALL),
    );
    errdefer os.close(ret);

    var sll = std.mem.zeroes(c.sockaddr_ll);
    sll.sll_family = c.AF_PACKET;
    sll.sll_ifindex = @intCast(c_int, c.if_nametoindex(net_if.ptr));
    sll.sll_protocol = c.htons(c.ETH_P_ALL);
    try os.bind(ret, @ptrCast(*std.c.sockaddr, &sll), @sizeOf(c.sockaddr_ll));

    return ret;
}
