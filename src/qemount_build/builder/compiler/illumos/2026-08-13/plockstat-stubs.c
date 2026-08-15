/*
 * The appliance does not ship DTrace.  libc's lock probes are optional, but
 * its normal build uses the DTrace compiler to provide these symbols.
 */

#define PROBE(name) void __dtrace_plockstat___##name(void) { }

PROBE(mutex__acquire)
PROBE(mutex__release)
PROBE(mutex__spin)
PROBE(mutex__spun)
PROBE(mutex__block)
PROBE(mutex__blocked)
PROBE(mutex__error)
PROBE(rw__acquire)
PROBE(rw__release)
PROBE(rw__block)
PROBE(rw__blocked)
PROBE(rw__error)
