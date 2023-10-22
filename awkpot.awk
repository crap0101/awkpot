
##############################################
# awkpot: miscellaneous utilities for (g)awk #
##############################################


@namespace "awkpot"

#XXX+TODO: write test

function dprint_real(arg) {
    # Prints arg on stderr, for real!
    print arg >> "/dev/stderr"
}

function dprint_fake(arg) {
    return 0 # prrrrrrrrrrrrrrrint... nope
}

function set_dprint(arg) {
    dprint = arg
}

function equals(val1, val2) {
    #XXX check if array
    return val1 == val2
}

function equals_typed(val1, val2) {
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


function get_tempfile(    cmd, ret, tempfile) {
    # Returns a string to the path of a temporary file.
    cmd = "mktemp"
    ret = ((cmd) | getline tempfile)
    close(cmd)
    if (ret < 0) {
	printf ("Error creating tempfile. ERRNO: %d\n", ERRNO) > "/dev/stderr"
	exit(ERRNO)
    }
    return tempfile
}

function run_command(command, nargs, args_array, must_exit, run_values,    i, cmd, ret, line, out) {
    # Runs $command with arguments retrieved from $args_array.
    # The latter must be a zero-based indexed array filled
    # with $nargs number of arguments, used to build the
    # command line to execute.
    # If any errors occours during the command executions *and* must_exit is
    # true, exits with ERRNO value, otherwise returns ERRNO, If everything
    # gone well, returns 1.
    # $run_values is an optional array in which will be stored some
    # information of the executed command, the indexes are
    # * output => command's stdout
    # * retcode => getline last return code
    # * errno => the ERRNO value, if errors occours    
    cmd = command " "
    for (i=0; i<nargs; i++)
	cmd = cmd " " args_array[i]
    run_values["cmdline"] = cmd
    while ((ret = (cmd | getline line)) > 0)
	out = out "\n" line
    close(cmd)
    if (ret < 0) {
	run_values["output"] = out
	run_values["retcode"] = ret
	run_values["errno"] = ERRNO
	if (must_exit) {
	    printf ("Error creating tempfile. ERRNO: %d\n", ERRNO) > "/dev/stderr"
	    exit(ERRNO)
	} else {
	    return ERRNO
	}
    }
    run_values["retcode"] = ret
    run_values["output"] = out
    return 1
}


function read_file(filename, dest, start_index,   line, ret, idx) {
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

