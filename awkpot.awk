
##############################################
# awkpot: miscellaneous utilities for (g)awk #
##############################################


@namespace "awkpot"
# Cfg. "arrlib" @ https://github.com/crap0101/awk_arrlib

function dprint_real(arg) {
    # Prints arg on stderr, for real!
    # Return true.
    print arg >> "/dev/stderr"
    return 1
}

function dprint_fake(arg) {
    # Does nothing, and returns false.
    return 0 # prrrrrrrrrrrrrrrint... nope
}

function set_dprint(arg) {
    # Sets @dprint function to $arg.
    # awkpot provides <dprint_fake> (print nothing)
    # and <dprint_real> for printing to sderr.
    dprint = arg
}

function equals(val1, val2, type) {
    # Checks if $val1 equals $val2.
    # Arrays comparison evaluate always to true. (use arrlib::equals
    # to compare arrays). If $type is true,
    # checks also if the values are of the same type.
    if (awk::isarray(val1)) {
	if (awk::isarray(val2))
	    return 1
    } else {
	if (awk::isarray(val2))
	    return 0
	else {
	    if (! type)
		return val1 == val2
	    return equals_typed(val1, val2)
	}
    }
}

function equals_typed(val1, val2) {
    # Checks if $val1 equals $val2 and are both of the same time.
    # Not meant to be used directly (use the <equals> funcs with
    # the $type parameter, instead).
    return val1 == val2 && awk::typeof(val1) == awk::typeof(val2)
}

function set_sort_order(sort_type,    prev_sorted) {
    # Sets PROCINFO["sorted_in"] to $sort_type
    # Returns the previously sorting order string set.
    @dprint("actual sorting:" PROCINFO["sorted_in"])
    prev_sorted = PROCINFO["sorted_in"]
    PROCINFO["sorted_in"] = sort_type
    @dprint("new sorting:" PROCINFO["sorted_in"])
    return prev_sorted
}


function get_tempfile(must_exit,    cmd, ret, tempfile) {
    # Returns a string to the path of a temporary file
    # or an empty string if the command fails. In this case,
    # if the optional parameter $must_exit is true, exits with ERRNO value.
    # Uses the mktemp command.
    cmd = "mktemp"
    ret = (cmd | getline tempfile)
    close(cmd)
    if (ret < 0) {
	printf ("Error creating tempfile. ERRNO: %d\n", ERRNO) > "/dev/stderr"
	if (must_exit)
	    exit(ERRNO)
	tempfile = ""
    }
    return tempfile
}

function run_command(command, nargs, args_array, must_exit, run_values,    i, cmd, ret, line, out) {
    # Runs $command with arguments retrieved from $args_array.
    # The latter must be a zero-based indexed array filled
    # with $nargs number of arguments, used to build the
    # command line to execute.
    # If any errors occours during the command executions *and* must_exit is
    # true, exits with ERRNO value, otherwise returns 0. If everything
    # gone well, returns 1.
    # $run_values is an optional array in which some information of the
    # executed command will be stored, the indexes are:
    # * output => command's stdout
    # * retcode => <getline> last return code
    # * errno => the ERRNO value, if errors occours, or false.
    cmd = command " "
    out = ""
    for (i=0; i<nargs; i++)
	cmd = cmd " " args_array[i]
    run_values["cmdline"] = cmd
    while ((ret = ((cmd) | getline line)) > 0)
	out = out line "\n"
    close(cmd)
    run_values["output"] = out
    run_values["retcode"] = ret
    if (ret < 0) {
	if (must_exit) {
	    printf ("Error creating tempfile. ERRNO: %d\n", ERRNO) > "/dev/stderr"
	    exit(ERRNO)
	} else {
	    run_values["errno"] = ERRNO
	    return 0
	}
    }
    run_values["errno"] = ""
    return 1
}


function read_file_arr(filename, dest, start_index,   line, ret, idx) {
    # Reads $filename into the $dest array, one line per index
    # starting from $start_index (optional, default to 0).
    if (! start_index)
	idx = 0
    else
	idx = 0 + start_index
    while ((ret = (getline line < filename)) > 0)
	dest[idx++] = line
    if (ret < 0)
	printf ("Error reading <%s>. ERRNO: %d\n", filename, ERRNO) > "/dev/stderr"
    close(filename)
}


BEGIN {
    set_dprint("awkpot::dprint_fake")
}

