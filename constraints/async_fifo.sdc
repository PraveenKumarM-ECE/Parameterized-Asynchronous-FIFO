# Asynchronous FIFO Timing Constraints
# Units: nanoseconds
# Example constraints, not physical timing sign-off.

# Independent write and read clocks
create_clock -name wr_clk -period 10.000 [get_ports wr_clk]
create_clock -name rd_clk -period 14.000 [get_ports rd_clk]

# Independent clock domains
# These clocks have no defined phase relationship.
set_clock_groups -asynchronous \
    -group [get_clocks wr_clk] \
    -group [get_clocks rd_clk]

# Reset inputs are asynchronous.
# Reset release must follow the system reset protocol.
#
# Reset timing exceptions, input/output delays and
# synchronizer placement constraints are platform-specific
# and must be added during physical implementation.
