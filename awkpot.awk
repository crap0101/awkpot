
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


function check_defined(funcname, check_id) {
    # Checks if $funcname is available, searching
    # in the FUNCTAB array.
    # If $check_id is true, check also the
    # PROCINFO["identifiers"] array.
    if (! (funcname in FUNCTAB)) {
	if (! check_id) {
	    return 0
	} else {
	    if (funcname in PROCINFO["identifiers"]) {
		if (PROCINFO["identifiers"][funcname] == "user") {
		    return 1
		} else if (PROCINFO["identifiers"][funcname] == "untyped") {
		    @dprint(sprintf("check_defined: <%s> is <%s>",
				    funcname, PROCINFO["identifiers"][funcname]))
		    return 1
		} else {
		    printf("check_defined: Unknown value for <%s>: %s\n",
			   funcname, PROCINFO["identifiers"][funcname]) > "/dev/stderr"
		    return 0
		}
	    } else {
		return 0
	    }
	}
    } else {
	return 1
    }
}


function _mkbool(expression) {
    # Private function for "creating" bool values. 
    # Returns 1 if $expression evaluate to a true value, else 0.
    # For (g)awk version without the mkbool function.
    if (expression)
	return 1
    return 0
}

function cmkbool(expression) {
    # Returns true if $expression evaluate to a true value, else false.
    # For (g)awk version without the mkbool function.
    # Uses either awkpot::_mkbool or,
    # if available, the builtin mkbool function.
    return @_cmkbool(expression)
}


function set_mkbool() {
    # Checks and set a sort-of-a-kind "mkbool" function.
    # For (g)awk version without the builtin mkbool function,
    # sets the function used by cmkbool (awkpot::_mkbool function),
    # otherwise uses the builtin mkbool function.
    # Returns a string of the setted name.
    if (! check_defined("mkbool"))
	_cmkbool = "awkpot::_mkbool"
    else
	_cmkbool = "mkbool"
    return _cmkbool
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
    @dprint(sprintf("set_sort_order: actual sorting: <%s>", PROCINFO["sorted_in"]))
    prev_sorted = PROCINFO["sorted_in"]
    PROCINFO["sorted_in"] = sort_type
    @dprint(sprintf("set_sort_order: new sorting: <%s>", PROCINFO["sorted_in"]))
    return prev_sorted
}


function exec_command(command, must_exit) {
    # Executes $command using the built-in system() function.
    # Returns true if command succedes, 0 if fail.
    # If $must_exit is true, exit with the $command return code.
    if (! command) {
	printf("exec_command: <%s> seems not a valid command name\n", command) > "/dev/stderr"
	return 0
    }
    if (0 != (ret = system(command))) {
	printf ("exec_command: Error! <%s> exit status is: %d\n", command, ret) > "/dev/stderr"
	if (must_exit)
	    exit(ret)
	else
	    return 0
    }
    return 1
}


function run_command(command, nargs, args_array, must_exit, run_values,    i, cmd, ret, line, out) {
    # Alternative method to run a command using <getline>,
    # purposely avoiding the built-in system() function (see exec_command).
    #
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
	    printf ("run_command: Error creating tempfile. ERRNO: %d\n", ERRNO) > "/dev/stderr"
	    exit(ERRNO)
	} else {
	    run_values["errno"] = ERRNO
	    return 0
	}
    }
    run_values["errno"] = ""
    return 1
}


function random(seed, upto, init) {
    # Convenience function to generate pseudo-random numbers
    # using some builtin functions.
    # $seed is a positive integer used (if $init is true) to initialize
    # the random number generator (otherwise systime() is used).
    # $upto (default to 1000) is the upper limit of the
    # generated number (from 0 to $upto - 1).
    # To get random numbers calls this function a first time as
    #
    # random(0, 0, 1)
    #
    # to set a casual seed, then call random() without arguments
    # to get random values. Giving the same value to $seed
    # assures predictable sequence from run to run.
    if (! upto)
	upto = 1000
    if (! seed)
	seed = awk::systime() % 1000
    if (init)
        srand(seed)
    return int(upto * rand())
}


function check_load_module(name, is_ext,   cmd, exe) {
    # Checks if the awk module or the extension $name
    # is available in the system. If $name is an extension
    # to load, the (optional) $is_ext parameter must be set to true.
    # Return true if it's, else 0.

    # For some reasons ARGV[0] is unreliable
    # https://www.gnu.org/software/gawk/manual/gawk.html#index-dark-corner-31
    # so we fall back to use a plain "awk" name.
    #
    #exe = ARGV[0] ? (match(ARGV[0], "awk") ? ARGV[0] : "awk") : "awk"
    exe = "awk"
    if (is_ext)
        cmd = sprintf("%s -l %s 'BEGIN {exit(0)}'", exe, name)
    else
        cmd = sprintf("%s -i %s 'BEGIN {exit(0)}'", exe, name)
    return exec_command(cmd)
}


function force_type(val, type, dest,    _reg) {
    # Tries to force the type of $val to $type.
    # Save conversion and other info in the $dest array.
    # Returns 1 if the conversion succeeded or 0 if errors.
    #
    # Supported $val types:
    # * string, number, bool, strnum, regexp, unassigned, untyped
    # Supported $type values:
    # * "string", "number", "regexp", "bool"
    # NOTE: $type bool require a (g)awk version with the builtin
    # mkbool function. In Sostitution the awkpot::set_mkbool
    # function can be used to set the custom _mkbool in his place,
    # however the returned value will be of type "number").
    # Unsupported conversion:
    # * regexp to (number|bool|strnum)
    # * any type but regexp to regexp
    # * unassigned and untyped conversion $type are clearly not an option in any case :).
    delete dest
    dest["val"] = val
    dest["val_type"] = awk::typeof(val)
    dest["newval"]
    dest["newval_type"]
    switch (type) {
	case "string":
	    if (dest["val_type"] != "string")
		dest["newval"] = val ""
	    else
		dest["newval"] = val
	    break
        case "number":
	    if (dest["val_type"] == "regexp") {
		printf ("force_type: Cannot convert from <%s> to <%s> \n",
			dest["val_type"], type) > "/dev/stderr"
		return 0
	    } else if (dest["val_type"] == "number") {
		dest["newval"] = val
	    } else {
		dest["newval"] = awk::strtonum(val)
	    }
	    break
	case "bool":
	    if (dest["val_type"] == "regexp") {
		printf ("force_type: Cannot convert from <%s> to <%s> \n",
			dest["val_type"], type) > "/dev/stderr"
		return 0
	    } else if (dest["val_type"] == "bool") {
		dest["newval"] = val		
	    } else {
		dest["newval"] = cmkbool(val)
	    }
	    break
	case "regexp": #XXX+TODO: find a workaround (c extension?)
	    # NOTE: https://www.gnu.org/software/gawk/manual/gawk.html#Strong-Regexp-Constants
	    # regexp-typed variable creation on runtime don't works consistently on gawk 5.1
	    if (dest["val_type"] != "regexp") {
		printf ("force_type: Cannot convert from <%s> to <%s> \n",
			dest["val_type"], type) > "/dev/stderr"
		return 0
	    } else
		dest["newval"] = val
	    break
        default:
	    printf ("force_type: Unkown conversion type <%s>\n", type) > "/dev/stderr"
	    return 0
    }
    dest["newval_type"] = awk::typeof(dest["newval"])
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
	printf ("read_file_arr: Error reading <%s>. ERRNO: %d\n", filename, ERRNO) > "/dev/stderr"
    close(filename)
}


BEGIN {
    set_dprint("awkpot::dprint_fake")
    set_mkbool()
}

