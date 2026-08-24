# Synopsys environment setup

Everything needed to get Fusion Compiler and a PDK onto `PATH` for the labs. Replaces `/usr/local/bin/synopsys.cshrc`, which sets three variables and whose tool paths no longer resolve.

## Files

| File | Purpose |
|---|---|
| `syn` | User-facing command. Lists kits, or loads one into a fresh `tcsh`. |
| `setup.cshrc` | Entry point. Sources the tool file, then the kit file, then reports both. |
| `synopsys_tools.cshrc` | `PATH`, licence servers, per-tool version discovery. PDK-independent. |
| `kits/<kit>.cshrc` | Every path for one PDK, exported to the environment. |
| `kits/<kit>.tcl` | The same paths under shorter names, plus cell names, corners and layers. Lab scripts source this. |
| `build_ndm.tcl` | One-time build of the NDM reference libraries Fusion Compiler needs. |
| `check_ndm.tcl` | Verifies that build produced usable libraries. |

- Load order is `syn` -> `setup.cshrc` -> `synopsys_tools.cshrc` -> `kits/<kit>.cshrc`.
- Adding a tool is one row in a table; adding a PDK is two files in `kits/`.

## Setup

Prerequisites: a machine with the Synopsys install under `/eda/synopsys`, the TSMC back-end libraries under `/eda/cadence_tools`, `tcsh`, and a Synopsys licence. Scripts use the set up specific to `ee-mill2`; anywhere else, see *Site-specific values* below.

1. **Get the files onto the server.** From your local checkout:

   ```bash
   cd ~
   mkdir Labs
   cd Labs
   git clone git@github.com:sne-samal/vlsi-tooling.git
   ```

2. **Make the wrapper executable.** `scp` does not always preserve the bit:

   ```bash
   chmod +x ~/Labs/tools/syn
   ```

3. **List the available kits.** Confirms the wrapper runs and finds `kits/`:

   ```bash
   ~/Labs/tools/syn
   ```

4. **Load a kit.** This replaces your shell with a fresh `tcsh` carrying the environment:

   ```bash
   ~/Labs/tools/syn tsmc65LP
   ```

   It prints a `--- tools ---` block with the resolved path of each tool, then the kit's
   tech file, reference libraries and Tcl setup, then the licence servers. Any tool
   showing `NOT ON PATH` means no matching directory was found under `$SYN_DIR`.
   `lm_shell`, used in step 6, is not in that list; check it with `which lm_shell`.

5. **Check the environment by hand** (optional):

   ```bash
   which fc_shell
   echo $SYN_KIT_TCL
   ls -l $SYN_TECH_FILE
   ```

6. **Build the NDM reference libraries.** One time per user, unless a shared copy already
   exists. Fusion Compiler cannot read the Milkyway libraries the kit ships, so this
   converts LEF plus Liberty `.db` into NDM. Output is about 36 MB:

   ```bash
   lm_shell -f ~/Labs/tools/build_ndm.tcl
   ```

7. **Verify the build.** Checks contents rather than exit status, because a failed build
   can still exit cleanly with an empty library:

   ```bash
   fc_shell -batch -f ~/Labs/tools/check_ndm.tcl
   ```

   Expect `PASS` and `special cells : all 28 present`.

8. **Unload** with `exit`, which drops you back into the shell you started from. Only one
   kit can be loaded at a time; load another by exiting first.

## Site-specific values

Four values are hardcoded to this server and account. Each is marked in the scripts with a
`SITE:` comment, so:

```bash
grep -rn "SITE:" tools/
```

| Value | File | Set to | Change it if |
|---|---|---|---|
| `SYN_DIR` | `synopsys_tools.cshrc` | `/eda/synopsys/2025-26/RHELx86` | The Synopsys install lives elsewhere, or the academic year rolls over. |
| `SNPSLMD_LICENSE_FILE` | `synopsys_tools.cshrc` | Three Imperial EEE licence servers | Using different license location(s). |
| `TSMC65_HOME` | `kits/tsmc65LP.cshrc` | `/eda/cadence_tools/kits/tsmc/beLibs/65nm/TSMCHOME/digital` | The TSMC kit is installed elsewhere. |
| `SYN_NDM_DIR` | `kits/tsmc65LP.cshrc` | `$HOME/vlsi_ndm` | You want one shared read-only library rather than a copy per user. |

`SYN_NDM_DIR` is the one most likely to need changing, and it does not require editing the
file. Export it before loading, and the kit will use it:

```bash
setenv SYN_NDM_DIR /path/to/shared/ndm
tools/syn tsmc65LP
```

Everything else in `kits/tsmc65LP.cshrc` is a deliberate choice of library rather than a
path to a machine: the 9lmT2 metal stack, the 7-track standard-Vt cells, and the matching
TLUPlus files. These three must stay consistent with each other.

## Adding a tool

Add one row to the table in `synopsys_tools.cshrc`, of the form
`"<install directory prefix>:<variable name>"`. The setup finds the newest directory
matching `<prefix>_*` under `$SYN_DIR` and appends its `bin` to `PATH`.

The trailing underscore is part of the glob and matters: `TESTMAX_*` must not also match
`TESTMAX-ALE_*`. Never put a literal `*` in that list; `csh` expands the word list of a
`foreach` and a pattern matching nothing aborts the script.

To pin a version rather than take the newest, export it before loading:

```bash
setenv SNPS_FC_VERSION FS-COMPILER_2025.06-SP2a
tools/syn tsmc65LP
```

## Adding a PDK

Two files in `kits/`, and nothing else:

- `<kit>.cshrc` - paths only. Its first line must be a `# DESCRIPTION:` comment, which is
  what `syn` prints in the kit listing. It must export the variables listed in section 5 of
  `notes/environment_setup.md`.
- `<kit>.tcl` - reads those variables back out of the environment, and adds the
  library-specific knowledge that has no shell equivalent: cell names, corner labels,
  routing directions, site name.

Lab scripts never contain a PDK path. They open with `source $env(SYN_KIT_TCL)` and use the
names defined there, so switching PDK is a matter of loading a different kit.

## What this changes from the original setup script

The original was three lines: set `SYN_DIR`, append four `bin` directories to `PATH`, set
`SNPSLMD_LICENSE_FILE`. The licence line is carried over unchanged. The rest is new.

- **Tool paths are discovered, not hardcoded.** The original's four paths (`syn/bin`,
  `tetramax/bin`, `formality/bin`, `primetime/bin`) describe a 2019 install layout. The
  current tree uses versioned per-tool directories, so none of them resolved and no tool
  reached `PATH`. Discovery means a Synopsys upgrade needs no edit.
- **Twelve tools instead of four**, including Fusion Compiler, ICC2, VCS, Verdi, IC
  Validator, StarRC, Library Compiler and Custom Compiler. None of the tools the labs
  actually use were in the original.
- **`VCS_HOME`, `VERDI_HOME`, `NOVAS_HOME` are set.** Those tools read them at startup and
  will not run on a `PATH` entry alone.
- **`LM_LICENSE_FILE` is appended to**, not overwritten, for the tools that still fall back
  to the generic FlexLM variable.
- **Failures are reported.** Missing install root, missing tool directory and missing kit
  file each produce a message. The load prints what resolved, so a problem surfaces at
  load time instead of as `command not found` an hour later.
- **The PDK is included.** The original was tools-only. Tech file, reference libraries,
  TLUPlus, simulation models, cell names and corners now come from the kit files.
- **One kit per shell, with a clean unload.** `syn` guards against double-loading and
  `exit` restores the shell you came from.
- **`~/.cshrc` is never touched.**