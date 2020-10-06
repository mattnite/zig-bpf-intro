const std = @import("std");
const mem = std.mem;
const atomic = std.atomic;

usingnamespace std.os.linux.BPF.kern;
const BPF = std.os.linux.BPF;

export var events linksection("maps") = PerfEventArray.init(256, 0);

export fn bpf_prog(ctx: *SkBuff) linksection("socket1") c_int {
    var time = ktime_get_ns();
    events.event_output(ctx, BPF.F_CURRENT_CPU, mem.asBytes(&time)) catch {};
    return 0;
}
