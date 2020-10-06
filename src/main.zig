const std = @import("std");
const bpf = @import("bpf");
const mem = std.mem;

usingnamespace @import("common.zig");

const BPF = std.os.linux.BPF;
const os = std.os;
const assert = std.debug.assert;

const c = @cImport({
    @cInclude("net/if.h");
});

// tell the compiler to include the multithreaded event loop
pub const io_mode = .evented;

// embed an external file into the .rodata section
const probe = @embedFile("probe.o");

// at compile time we parse the embedded elf file, if there is no section named
// 'socket1' compilation fails
comptime {
    @setEvalBranchQuota(4000);
    assert(bpf.elf.has_section(probe, "socket1"));
}

fn consume_events(perf_buffer: *BPF.PerfBuffer) void {
    while (perf_buffer.running.get()) {
        const payload = perf_buffer.get();

        switch (payload.event) {
            .sample => |data| {
                std.debug.print("cpu: {}, sample: {}\n", .{
                    payload.cpu,
                    mem.bytesToValue(usize, data[0..8]),
                });
                perf_buffer.allocator.free(data);
            },
            .lost => |cnt| {
                std.debug.print("cpu: {}, lost: {}\n", .{ payload.cpu, cnt });
            },
        }
    }
}

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var obj = try bpf.Object.init(&gpa.allocator, probe);
    defer obj.deinit();

    try obj.load();
    defer obj.unload();

    const sock_fd = try create_raw_socket("lo");
    defer os.close(sock_fd);

    const prog = obj.find_prog("socket1") orelse unreachable;
    try os.setsockopt(sock_fd, c.SOL_SOCKET, c.SO_ATTACH_BPF, mem.asBytes(&prog));

    const perf_event_array = try BPF.PerfEventArray.init(BPF.MapInfo{
        .fd = obj.find_map("events") orelse return error.NoEventsMap,
        .def = BPF.kern.PerfEventArray.init(256, 0).map.def,
    });

    var perf_buffer = try BPF.PerfBuffer.init(&gpa.allocator, perf_event_array, 64);
    _ = async perf_buffer.run();
    _ = async consume_events(&perf_buffer);

    suspend;
}
