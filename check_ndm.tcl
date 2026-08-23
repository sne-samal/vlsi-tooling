####################################################################
##
##  Sanity check on the NDM built by build_ndm.tcl.
##
##  Author:   Sne Samal
##  Date:     2026-08-23
##  Version:  1.0
##
##      tools/syn tsmc65LP
##      fc_shell -f tools/check_ndm.tcl
##
##  Checks contents, not exit status: a build that printed no obvious
##  error can still produce an empty library.
##
####################################################################

source $env(SYN_KIT_TCL)

# REF_LIBS is a list: the timed library plus the physical-only one.
foreach lib $REF_LIBS {
    if { ![file exists $lib] } {
        puts "FAIL: $lib does not exist. Run build_ndm.tcl first."
        exit 1
    }
    open_lib $lib
    report_lib [current_lib]
}

set all    [sizeof_collection [get_lib_cells -quiet */*]]
set frames [sizeof_collection [get_lib_cells -quiet */*/frame]]

puts "----------------------------------------"
puts " library cells       : $all"
puts " with a frame view   : $frames"

# The PnR scripts ask for these by name. A missing one otherwise
# surfaces much later as a confusing placement or CTS error.
set wanted [concat [list $TAP_CELL $TIE_HI_CELL $TIE_LO_CELL] \
                   $FILLER_CELLS $CTS_BUFFERS $CTS_INVERTERS]
set missing {}
foreach c $wanted {
    if { [sizeof_collection [get_lib_cells -quiet */$c]] == 0 } {
        lappend missing $c
    }
}

if { [llength $missing] } {
    puts " special cells       : [expr {[llength $wanted] - [llength $missing]}] of [llength $wanted]"
    puts ""
    puts "FAIL: these cells are not in the library:"
    foreach c $missing { puts "  $c" }
} else {
    puts " special cells       : all [llength $wanted] present"
    puts ""
    puts "PASS"
}
puts "----------------------------------------"
