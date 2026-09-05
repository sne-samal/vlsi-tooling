####################################################################
##
##  One-time NDM reference library build for tsmc65LP.
##
##  Author:   Sne Samal
##  Date:     2026-08-23
##  Version:  1.0
##
##  Run with Library Manager, NOT fc_shell, once the kit is loaded:
##
##      lm_shell -f $SYN_TOOLS_DIR/build_ndm.tcl
##
##  Build once, then point create_lib at the result. Output is about
##  36 MB on disk. Built from LEF plus db because the kit ships
##  Milkyway, not NDM.
##
####################################################################

source $env(SYN_KIT_TCL)

set LIB_NAME $env(TSMC65_STDCELL)
set NDM_DIR  $env(SYN_NDM_DIR)

file mkdir $NDM_DIR

####################################################################
## Application options
####################################################################
# TSMC Liberty does not declare related_power_pin on every cell.
set_app_options -as_user_default \
    -name lib.workspace.allow_missing_related_pg_pins -value true

# Keep the LEF metal blockages instead of merging them.
set_app_options -as_user_default \
    -name lib.physical_model.preserve_metal_blockage -value auto

# Match the bus naming used by the Verilog and SDC.
set_app_options -as_user_default -name design.bus_delimiters -value {[]}

####################################################################
## Pass 1: timed cells
####################################################################
# -flow normal emits only cells present in both the LEF and the db, so
# taps and fillers are dropped here and picked up by pass 2.

create_workspace $LIB_NAME \
    -technology   $TECH_FILE \
    -flow         normal \
    -scale_factor $SCALE_FACTOR

read_lef $STD_LEF

foreach corner $CORNER_LABELS {
    set db $STD_DB_DIR/${LIB_NAME}${corner}.db
    if { ![file exists $db] } {
        puts "ERROR: missing $db"
        continue
    }
    read_db $db -process_label $corner
}

# On failure, rerun lm_shell interactively and use
# "check_workspace -details all".
process_workspaces -force -directory $NDM_DIR -output ${LIB_NAME}_frame_timing.ndm

remove_workspace

####################################################################
## Pass 2: physical-only cells
####################################################################
# -flow physical_only emits the cells found only in the physical files,
# so the taps and the FILL family. The db is read here to tell the flow
# which names to exclude, or every cell would appear in both libraries.
# One corner is enough: all three db files hold the same cell set.

create_workspace ${LIB_NAME}_po \
    -technology   $TECH_FILE \
    -flow         physical_only \
    -scale_factor $SCALE_FACTOR

read_lef $STD_LEF
read_db  $STD_DB_DIR/${LIB_NAME}[lindex $CORNER_LABELS 0].db

process_workspaces -force -directory $NDM_DIR -output ${LIB_NAME}_physical_only.ndm

remove_workspace

####################################################################
## Result
####################################################################
# process_workspaces can return without writing anything, so check the
# outputs are on disk before claiming success. Without the exit,
# lm_shell drops into an interactive prompt.

set missing {}
foreach lib $REF_LIBS {
    if { ![file exists $lib] } { lappend missing $lib }
}

puts "=========================================="
puts " NDM directory : $NDM_DIR"
puts "   ${LIB_NAME}_frame_timing.ndm   corners: $CORNER_LABELS"
puts "   ${LIB_NAME}_physical_only.ndm  taps and fillers"
puts "------------------------------------------"

if { [llength $missing] } {
    puts " BUILD FAILED. Not written:"
    foreach lib $missing { puts "   $lib" }
    puts ""
    puts " Search this log upwards for the first \"Error\" line."
    puts "=========================================="
    exit 1
}

puts " BUILD OK. Now check the contents:"
puts "   fc_shell -f \$SYN_TOOLS_DIR/check_ndm.tcl"
puts "=========================================="
exit 0
