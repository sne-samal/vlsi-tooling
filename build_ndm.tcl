####################################################################
##
##  One-time NDM reference library build for tsmc65LP.
##
##  Author:   Sne Samal
##  Date:     2026-08-23
##  Version:  1.0
##
##  Run with Library Manager, NOT fc_shell:
##
##      tools/syn tsmc65LP
##      lm_shell -f tools/build_ndm.tcl
##
##  Build once, then every lab points create_lib at the result.
##  A setup step, not a lab step. Output is about 36 MB on disk.
##
##  Built from LEF plus db because the kit ships Milkyway, not NDM.
##
####################################################################

source $env(SYN_KIT_TCL)

set LIB_NAME $env(TSMC65_STDCELL)
set NDM_DIR  $env(SYN_NDM_DIR)

file mkdir $NDM_DIR

####################################################################
## Application options
####################################################################
# Only the ones addressing expected failure modes. Full vendor list is
# in notes/ndm_creation.txt.

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
# -flow normal takes physical from LEF and timing from one db per
# corner. It emits only cells present in BOTH, so taps and fillers,
# which have no timing arcs, are dropped here and picked up by pass 2.

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

# Checks and commits in one step. On failure, rerun lm_shell
# interactively and use "check_workspace -details all".
process_workspaces -force -directory $NDM_DIR -output ${LIB_NAME}_frame_timing.ndm

remove_workspace

####################################################################
## Pass 2: physical-only cells
####################################################################
# -flow physical_only emits the cells found ONLY in the physical files,
# so the taps and the FILL family. The db is read here too, and is not
# redundant: it tells the flow which names to exclude, otherwise every
# cell would be duplicated across the two libraries. One corner is
# enough since all three db files hold the same cell set.

create_workspace ${LIB_NAME}_po \
    -technology   $TECH_FILE \
    -flow         physical_only \
    -scale_factor $SCALE_FACTOR

read_lef $STD_LEF
read_db  $STD_DB_DIR/${LIB_NAME}[lindex $CORNER_LABELS 0].db

process_workspaces -force -directory $NDM_DIR -output ${LIB_NAME}_physical_only.ndm

remove_workspace

puts "=========================================="
puts " Built in $NDM_DIR"
puts "   ${LIB_NAME}_frame_timing.ndm   corners: $CORNER_LABELS"
puts "   ${LIB_NAME}_physical_only.ndm  taps and fillers"
puts "=========================================="
