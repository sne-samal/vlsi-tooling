# DESCRIPTION: TSMC 65nm Low Power, 9 metal, 7-track standard cells
#############################################################
#
#  Kit paths for tsmc65LP. Sourced by setup.cshrc.
#
#  Author:   Sne Samal
#  Date:     2026-08-23
#  Version:  1.0
#
#  Paths only. The Tcl half, kits/tsmc65LP.tcl, reads these back out
#  of the environment so there is one source of truth.
#
#  Everything is pinned to ONE metal stack: technology file, cell LEF
#  and TLUPlus must describe the same stack or the library build fails
#  with "cannot find via" errors.
#
#############################################################

# SITE: TSMC back-end libraries on ee-mill2. Change for another machine.
setenv TSMC65_HOME /eda/cadence_tools/kits/tsmc/beLibs/65nm/TSMCHOME/digital

# 9 metal layers, top 2 thick.
setenv TSMC65_STACK   9lmT2

# 7-track standard Vt cells. The kit's other six libraries are hvt/lvt
# variants and the tpbn65v pad library.
setenv TSMC65_STDCELL tcbn65lpbwp7t
setenv TSMC65_MW      $TSMC65_HOME/Back_End/milkyway/tcbn65lpbwp7t_141a

# --- Inputs to the one-time NDM build -------------------------------

setenv SYN_TECH_FILE  $TSMC65_MW/techfiles/tsmcn65_${TSMC65_STACK}.tf
setenv SYN_STD_LEF    $TSMC65_HOME/Back_End/lef/tcbn65lpbwp7t_141a/lef/${TSMC65_STDCELL}_${TSMC65_STACK}.lef
setenv SYN_STD_DB_DIR $TSMC65_MW/frame_only/${TSMC65_STDCELL}/LM

# --- Built NDM reference library ------------------------------------

# SITE: per-user NDM location, about 36 MB once built. Set SYN_NDM_DIR
# before loading the kit to point at a shared read-only copy instead:
#   setenv SYN_NDM_DIR /path/to/shared/ndm ; tools/syn tsmc65LP
if ( ! $?SYN_NDM_DIR ) setenv SYN_NDM_DIR $HOME/vlsi_ndm

# Two libraries, not one. Taps and fillers have no timing, so they are
# absent from the timed build and only exist in the physical-only one.
# Both must be on ref_libs or placement and filler insertion fail late.
setenv SYN_REF_LIBS   "$SYN_NDM_DIR/${TSMC65_STDCELL}_frame_timing.ndm $SYN_NDM_DIR/${TSMC65_STDCELL}_physical_only.ndm"

# --- RC extraction ---------------------------------------------------
# TLUPlus belongs to the metal stack, not the cell library.
# 1p09m+alrdl = 1 poly, 9 metal, aluminium redistribution; top2 pairs
# with the T2 in the stack name above.
#
# No -layermap is passed: the kit ships no tf-to-ITF map, and the
# gdsout_*.map files are GDS stream-out maps, a different thing. Layer
# names are then assumed identical on both sides, which holds since
# both come from TSMC. check_kit in the Tcl half verifies the files.

setenv SYN_TLUPLUS_DIR $TSMC65_MW/techfiles/tluplus
setenv SYN_TLUPLUS_MAX $SYN_TLUPLUS_DIR/cln65lp_1p09m+alrdl_rcworst_top2.tluplus
setenv SYN_TLUPLUS_MIN $SYN_TLUPLUS_DIR/cln65lp_1p09m+alrdl_rcbest_top2.tluplus
setenv SYN_TLUPLUS_TYP $SYN_TLUPLUS_DIR/cln65lp_1p09m+alrdl_typical_top2.tluplus

# --- Simulation models ----------------------------------------------

setenv SYN_SIM_MODELS $TSMC65_HOME/Front_End/verilog/tcbn65lpbwp7t_141a/${TSMC65_STDCELL}.v

# --- Tcl half, sourced by every lab script --------------------------

setenv SYN_KIT_TCL $SYN_TOOLS_DIR/kits/tsmc65LP.tcl
