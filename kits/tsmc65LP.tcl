####################################################################
##
##  TSMC 65nm Low Power kit definition for Fusion Compiler.
##
##  Author:   Sne Samal
##  Date:     2026-08-23
##  Version:  1.0
##
##  Sourced at the top of every flow script:
##
##      source $env(SYN_KIT_TCL)
##
##  Paths come from the environment, set by kits/tsmc65LP.cshrc.
##  Everything below that is library knowledge with no shell equivalent.
##
####################################################################

set TECH_FILE   $env(SYN_TECH_FILE)
set REF_LIBS    $env(SYN_REF_LIBS)
set STD_LEF     $env(SYN_STD_LEF)
set STD_DB_DIR  $env(SYN_STD_DB_DIR)
set SIM_MODELS  $env(SYN_SIM_MODELS)
set TLUPLUS_MAX $env(SYN_TLUPLUS_MAX)
set TLUPLUS_MIN $env(SYN_TLUPLUS_MIN)
set TLUPLUS_TYP $env(SYN_TLUPLUS_TYP)

# Stream out.
set GDS_MAP     $env(SYN_GDS_MAP)
set CELL_GDS    $env(SYN_CELL_GDS)

####################################################################
## Database units
####################################################################
# Units per micron, passed to create_workspace -scale_factor. Must
# match the tech file: tsmcn65_9lmT2.tf declares lengthPrecision 1000,
# so one internal unit is 1 nm. The tool default of 10000 is wrong here.

set SCALE_FACTOR 1000

####################################################################
## Corners
####################################################################
# Labels are assigned at NDM build time by read_db -process_label and
# selected by set_process_label. They match the suffix on the kit .db
# filenames. Voltage and temperature come from the .lib
# nom_voltage/nom_temperature fields.
#
#   wc  worst case  1.08V  125C  slow
#   tc  typical     1.20V   25C
#   bc  best case   1.32V    0C  fast   (0C, not the usual -40C)
#

set CORNER_LABELS { wc tc bc }

set CORNER_VOLTAGE(wc) 1.08
set CORNER_VOLTAGE(tc) 1.20
set CORNER_VOLTAGE(bc) 1.32

set CORNER_TEMP(wc)  125
set CORNER_TEMP(tc)   25
set CORNER_TEMP(bc)    0

####################################################################
## Site and routing layers
####################################################################
# Library Manager renames the LEF "core7T" site to "unit" (LEFR-064).
# 0.2 x 1.4 um, the 1.4 being the 7-track row height. The library's
# other site, "gaunit", is unused.

set SITE_NAME unit

# As declared in the LEF (SYMMETRY Y). Tap insertion still warns
# LGL-031 about limited orientations; rows come out R0 either way.

set SITE_SYMMETRY Y

# The tech file gives every layer an "unknown" preferred direction, so
# setting them explicitly silences NEX-001 and DPUI-924. Values from the
# LEF DIRECTION fields: odd layers horizontal, even vertical.

set HORIZONTAL_LAYERS { M1 M3 M5 M7 M9 }
set VERTICAL_LAYERS   { M2 M4 M6 M8 }

# Not M1: the cell rails are on M1, so a ring segment there is a short
# rather than a crossing. Vias connect the M2/M3 ring down to M1.

set RING_H_LAYER M3
set RING_V_LAYER M2

# Lowest routing layer, where the cells present their VDD and VSS pins.

set RAIL_LAYER M1

####################################################################
## Special cells
####################################################################

# For set_driving_cell: a mid-strength inverter. The library has INVD0
# through INVD12.

set DRIVE_CELL  INVD2BWP7T

set TAP_CELL    TAPCELLBWP7T
set TIE_HI_CELL TIEHBWP7T
set TIE_LO_CELL TIELBWP7T

# Largest first, which create_stdcell_fillers requires when the no_1x
# or advanced rules are in use.

set FILLER_CELLS { FILL64BWP7T FILL32BWP7T FILL16BWP7T FILL8BWP7T \
                   FILL4BWP7T FILL2BWP7T FILL1BWP7T }

set CTS_BUFFERS  { CKBD0BWP7T CKBD1BWP7T CKBD2BWP7T CKBD3BWP7T \
                   CKBD4BWP7T CKBD6BWP7T CKBD8BWP7T CKBD10BWP7T CKBD12BWP7T }

set CTS_INVERTERS { CKND0BWP7T CKND1BWP7T CKND2BWP7T CKND3BWP7T \
                    CKND4BWP7T CKND6BWP7T CKND8BWP7T CKND10BWP7T CKND12BWP7T }

# Maximum um between tap cell columns.

set TAP_DISTANCE 60

####################################################################
## Power nets
####################################################################

set PWR_NET VDD
set GND_NET VSS

####################################################################
## Sanity check
####################################################################
# A missing RC file is only a warning, and silently leaves layers with
# no parasitics.

proc check_kit {} {
    global TECH_FILE REF_LIBS TLUPLUS_MAX TLUPLUS_MIN TLUPLUS_TYP
    global GDS_MAP CELL_GDS
    set missing {}
    foreach f [concat [list $TECH_FILE $TLUPLUS_MAX $TLUPLUS_MIN $TLUPLUS_TYP \
                            $GDS_MAP $CELL_GDS] \
                      $REF_LIBS] {
        if { ![file exists $f] } { lappend missing $f }
    }
    if { [llength $missing] } {
        puts "ERROR: kit files missing:"
        foreach f $missing { puts "  $f" }
        return 0
    }
    puts "Kit tsmc65LP: all inputs present."
    return 1
}
