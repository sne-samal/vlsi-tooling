#############################################################
#
#  Entry point for the Synopsys lab environment.
#  Loads the tools, then one PDK kit, then reports both.
#
#  Author:   Sne Samal
#  Date:     2026-08-23
#  Version:  1.0
#
#  Normally reached through the wrapper:  tools/syn tsmc65LP
#  By hand:
#    setenv SYN_TOOLS_DIR <path to this directory>
#    setenv SYN_KIT tsmc65LP
#    source $SYN_TOOLS_DIR/setup.cshrc
#
#############################################################

# One if/else chain, because a sourced csh script cannot return early
# and "exit" would kill the calling shell.

if ( $?SYN_ENV_LOADED ) then

    echo "Synopsys environment already loaded (kit: $SYN_KIT)."
    echo "Type 'exit' to unload it, then load another."

else if ( ! $?SYN_TOOLS_DIR ) then

    echo "ERROR: SYN_TOOLS_DIR is not set."
    echo "       setenv SYN_TOOLS_DIR <path to labs_synopsys/tools>"

else

    if ( ! $?SYN_KIT ) setenv SYN_KIT tsmc65LP

    if ( ! -f "$SYN_TOOLS_DIR/kits/$SYN_KIT.cshrc" ) then

        echo "ERROR: no kit file $SYN_TOOLS_DIR/kits/$SYN_KIT.cshrc"

    else

        # Tools first (PATH, licences), then kit paths on top.
        source "$SYN_TOOLS_DIR/synopsys_tools.cshrc"
        source "$SYN_TOOLS_DIR/kits/$SYN_KIT.cshrc"

        setenv SYN_ENV_LOADED 1

        # Report what actually resolved, so a missing tool or a moved
        # install shows up now instead of as "command not found" later.
        echo "--- tools ---"
        foreach t ( fc_shell dc_shell icc2_shell vcs vlogan verdi icv lc_shell pt_shell fm_shell StarXtract )
            set p = `which $t |& head -1`
            if ( $status == 0 ) then
                printf '  %-11s %s\n' "$t" "$p"
            else
                printf '  %-11s NOT ON PATH\n' "$t"
            endif
        end
        unset t p

        echo "--- kit: $SYN_KIT ---"
        echo "  tech file   $SYN_TECH_FILE"
        echo "  ref libs    $SYN_REF_LIBS"
        echo "  tcl setup   $SYN_KIT_TCL"
        echo "--- licences ---"
        echo "  $SNPSLMD_LICENSE_FILE"

    endif

endif
