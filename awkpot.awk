
##############################################
# awkpot: miscellaneous utilities for (g)awk #
##############################################

# Copyright (C) 2023,  Marco Chieppa | crap0101
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3 of the License,
# or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, see <https://www.gnu.org/licenses>.


@namespace "awkpot"


############
# PRINTING #
############

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


function get_fmt(str, conv, maxspace, position,    len, fstr, lpad, rpad) {
    # Given a string $str and a conversion specifier $conv optionally
    # with a precision field (like "d", "u", ".2f", etc... default to "s")
    # builds a format string suitable to be used with (s)printf
    # for print $str in a space of $maxspace chars justified
    # as per $position, which must be one of "<c>":
    # "<" means justify to the left,
    # "c" means centered,
    # ">" means justify to the right.
    # If $maxspace < 1, returns the format string without any padding.
    if (! conv)
	conv = "s"
    fstr = sprintf("%" conv, str)
    len = length(fstr)
    if (maxspace < 1 || len >= maxspace)
	return "%" conv
    if (! position)
	position = "<"
    switch (position) {
	case "<":
	    return sprintf("%%-%d%s", maxspace, conv)
        case ">":
	    return sprintf("%%%d%s", maxspace, conv)
	case "c":
	    lpad = sprintf("%*s", int((maxspace - len) / 2), "")
	    rpad = sprintf("%*s", maxspace - len - length(lpad), "")
	    return sprintf("%s%%%s%s", lpad, conv, rpad)
	default:
	    printf("ERROR: get_fmt: unknown value <%s> for $position", position) >> "/dev/stderr"
	    exit(1)
    }
}

###########
# STRINGS #
###########

function join(arr, sep, order,    prev_sorted) {
    # Returns a string with the values or the $arr array joined
    # with the optional $sep separator (default "").
    # Array traversal can be controlled by the $order
    # parameter, a valid PROCINFO["sorted_in"] string
    # (default to "", keep the actual sortig order).
    # NOTE: works on flatten arrays only, any subarrays will cause a fatal error.
    # If you need advanced array's features see the arrlib's functions at:
    # https://github.com/crap0101/awk_arrlib
    s = ""
    if (order)
	prev_sorted = set_sort_order(order)
    for (i in arr)
	s = s arr[i] sep
    if (sep)
	s = substr(s, 1, length(s) - 1)
    if (order)
	set_sort_order(prev_sorted)
    return s
}


function join_range(arr, first, last, sep, order,    n, range_arr, prev_sorted) {
    # Like awkpot::join but only for elements in the $fist..$last range
    # (starting from 1) of the array traversal. Values < 1 for $first are
    # treated as 1, and for $last are treated as the $arr length.
    delete range_arr
    if (first < 1)
	first = 1
    if (last < 1)
	last = int("+inf")
    n = 1
    if (order)
	prev_sorted = set_sort_order(order)
    for (i in arr) {
	if (n >= first && n <= last)
	    range_arr[i] = arr[i]
	n += 1
    }
    if (order)
	set_sort_order(prev_sorted)
    return join(range_arr, sep, order)
}


function make_escape(s) {
    # Returns a printable form of the $s escape sequence string.
    # NOT all escaped sequences are covered as far, only
    # the most userful (we hope).
    # Proper $s values are:
    # "\0", "\n", "\a", "\b", "\f", "\r", "\t", "\v".
    # If $s is not one of them, $s itself will be returned.
    # NOTE (rational): the need of this function arise from the behaviour
    # within argument passing of those escape sequences to (g)awk programs
    # using, for example, the builtin getopt module, i.e. NOT using
    # the -v var=YYY switch NOR having this strings harcoded in the
    # programs text AND want to use them in the non literal form,
    # for example when setting ORS of OFS.
    if (! (s ~ /^\\[0abfnrtv]$/))
	return s
    switch (substr(s,2)) {
	case "0":return sprintf("%c", 0)
	case "a":return sprintf("%c", 7)
	case "b":return sprintf("%c", 8)
	case "f":return sprintf("%c", 12)
	case "n":return sprintf("%c", 10)
	case "r":return sprintf("%c", 13)
	case "t":return sprintf("%c", 9)
	case "v":return sprintf("%c", 11)
        default: return s
    }
}


function escape(s){
    # Escapes some tokens of the string $s.
    # Designed for formatting program's help() strings
    # readed from a plain text file.
    gsub(/\\[nbtvrfa0]|\\[0-9]{3}|\\[x][0-9a-fA-F]{1,2}|\\[u][0-9a-fA-F]{1,8}/,
	 "\\\\&",
	 s)
    gsub(/"/, "\\\"", s)
    return s
}


function startswith(str, start) {
    # Returns true if $str starts with $start, else false.
    if (str && ! start)
	return 0
    return substr(str, 1, length(start)) == start
}


function endswith(str, end) {
    # Returns true if $str ends in $end, else false.
    if (str && ! end)
	return 0
    return substr(str, length(str) - length(end) + 1, length(str)) == end
}


function strrepeat(str, count, sep) {
    # Returns $str joined $count times with itself,
    # optionally separated by $sep.
    # If count < 2 returns $str.
    if (count < 2)
	return str
    new_str = str
    while (--count)
	new_str = new_str sep str
    return new_str
}


###############
# GAWK INSIDE #
###############

function make_array_record(arr,    i) {
    # Puts the fields of the current record in $arr, deleting it first.
    # Returns the number of elements (NF).
    # NOTE: clone of the same arrlib's function,
    # just copied here for the semplicity.
    delete arr
    for (i = 1; i <= NF; i++) {
        arr[i] = $i
    }
    return NF
}


function get_record_string(first, last,   t, arr, seps) {
    # Rebuilds the current record, optionally from the $first field
    # to the $last field (default to the entire record).
    # Values < 1 for $first are treated as 1, and for $last are
    # treated as the record's number of fields.
    # Returns the resulting string.
    delete arr
    delete seps
    if (first < 1)
	first = 1
    if (last < 1)
	last = NF
    n = split($0, arr, FS, seps)
    if (first > 1)
	t = ""
    else
	t = seps[0]
    if (last < n)
	seps[last] = ""
    for (i=1; i<=n; i++)
	if ((i >= first) && (i <= last))
	    t = t arr[i] seps[i]
    return t
}


function get_version() {
    return PROCINFO["version"]
}

function cmp_version(v1, v2, cmp, major, minor, patch,    ret) {
    # 5.2.0 min for mkbool
    # Compares the two (g)awk version string $v1 and $v2
    # using the $cmp function (indirect call) which must
    # returns true if the two arguments compares equal.
    # $major, $minor and $patch can be sets to a true value
    # for comparing only the given part of the version number.
    # If $v1 is false gets the in-use gawk version.
    # Returns true if $v1 and $v2 compares equal, false otherwise.
    if (! v1)
	v1 = get_version()
    if (major || minor || patch) {
	ret = 0
	split(v1, v1_arr, ".")
	split(v2, v2_arr, ".")
	if (major)
	    if (! (ret = @cmp(v1_arr[1], v2_arr[1])))
		return 0
	if (minor)
	    if (! (ret = @cmp(v1_arr[2], v2_arr[2])))
		return 0
	if (patch)
	    if (! (ret = @cmp(v1_arr[3], v2_arr[3])))
		return 0
	return ret
    } else {
	return @cmp(v1, v2)
    }
}

##############
# COMPARISON #
##############

function eq(a, b) {
    # Returns true if $a equal $b, else false.
    return (a == b)
}

function ne(a, b) {
    # Returns true if $a not equal $b, else false.
    return (a != b)
}

function gt(a, b) {
    # Returns true if $a is greater than $b, else false.
    return (a > b)
}

function ge(a, b) {
    # Returns true if $a is greater or equal $b, else false.
    return (a >= b)
}

function lt(a, b) {
    # Returns true if $a is less than $b, else false.
    return (a < b)
}

function le(a, b) {
    # Returns true if $a is less than or equal $b, else false.
    return (a <= b)
}

function cmp(a, b, f) {
    # Bare-bones comparison function, see <compare> for a
    # more generic comparison function.
    # Compares $a and $b using the function $f, which
    # must takes two arguments and returns a true value
    # if succedes, false otherwise.
    # If $f is not provided or evaluates to false,
    # uses the awkpot::eq function instead.
    # Returns the result of $f($a, $b).
    if (! f)
	f = "awkpot::eq"
    return @f(a, b)
}

##################
# VARS AND TYPES #
##################

function make_regex(val) {
    # Calls the set __make_regex func.
    return @__make_regex(val)
}


function _make_regex(val) {
    # Returns a regexp-typed
    # variable from the value $val.
    # If fails creating the regex value, returns "unassigned".
    # NOTE: works in gawk >= 5.2.2
    # For older version, see the <make> function @ https://github.com/crap0101/awk_regexmix 
    re = @//
    sub(//, val, re)
    if (awk::typeof(re) != "regexp") {
	printf("make_regex fail: can't create regex type\n") >> "/dev/stderr"
	return
    }
    return re 
}


function set_make_regex(f) {
    # Set the provided $f function (which must takes *one* argument
    # and returns a regex-typed value) to the one to be used
    # instead to the default <make_regex> function, which doesn't works
    # on gawk versions <= 5.2.2 (the sub() trick doesn't works, instead of a
    # regexp value a string is returned).
    # A possible $f candidate can be the <make> function @ https://github.com/crap0101/awk_regexmix
    __make_regex = f
}


function get_make_regex() {
    # Returns the current function used by <make_regex>
    return __make_regex
}


function make_strnum(val,    __a) {
    # Returns a strnum-typed variable for the value $val,
    # if can be interpreted as a numeric string.
    # See https://www.gnu.org/software/gawk/manual/gawk.html#String-Type-versus-Numeric-Type
    split(val, __a, ":")
    if (awk::typeof(__a[1]) == "unassigned" || awk::typeof(__a[1]) == "untyped")
	return make_strnum("0")
    return __a[1]
}

function id(x) {
    # Identity function.
    return x
}

function len(x) {
    # Returns the length of $x using the builtin length() function.
    # NOTE: workaround for a bug in gawk version < 5.3.0 (at list in gawk 5.1.0)
    # when using the builtin's <length> function as indirect function call.
    # Should be used - for example - as the 2nd parameter of the arrlib::max_val function.
    return length(x)
}


function check_assigned(name) {
    # Returns true if $name already got a value,
    # false if untyped or unassigned.
    if (awk::typeof(name) == "untyped" || awk::typeof(name) == "unassigned")
	return 0
    return 1
}


function check_defined(funcname, check_id) {
    # Checks if $funcname is available, searching
    # in the FUNCTAB array.
    # If $check_id is true, check also the
    # PROCINFO["identifiers"] array.
    # In the latter case, can be used to check any other names.
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
			   funcname, PROCINFO["identifiers"][funcname]) >> "/dev/stderr"
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


function equals(val1, val2, type) {
    # Checks if $val1 equals $val2.
    # Arrays comparison (array vs array, array vs scalar)
    # evaluate always to true. (use arrlib::equal to compare arrays).
    # If $type is true, checks also if the values are of the same type.
    if (awk::isarray(val1)) {
	if (awk::isarray(val2))
	    return 1
    } else {
	if (awk::isarray(val2))
	    return 0
	else {
	    if (! type) {
		return cmp(val1, val2)
	    }
	    return equals_typed(val1, val2)
	}
    }
}


function equals_typed(val1, val2) {
    # Checks if $val1 equals $val2 and are both of the same time.
    # Not meant to be used directly (use the <equals> funcs with
    # the $type parameter, instead).
    return cmp(awk::typeof(val1), awk::typeof(val2)) && cmp(val1, val2)
}


function force_type(val, type, dest) {
    # Tries to force the type of $val to $type
    # mantaining the $val's meaning.
    # Saves conversion and other infos in the $dest array.
    # $dest array's elements are indexed as follow:
    # * "val" is the value passed to the function
    # * "val_type" is the $val type as per typeof()
    # * "newval" is the value after the tentative type coercion
    # * "newval_type" is the (probably new) "newval"'s type,
    #   as per the $type argument.
    # Returns 1 if the conversion succeeded or 0 if errors.
    #
    # SUPPORTED $val types:
    # * string, number, number|bool, strnum, regexp, unassigned, untyped
    # SUPPORTED $type values:
    # * string, number, regexp, number|bool, strnum, unassigned, untyped
    #
    # NOTE: $type bool require a (g)awk version with the builtin
    # mkbool function. In sostitution the awkpot::set_mkbool
    # function can be used to set the custom _mkbool in his place,
    # however the returned value will be of type "number").
    #
    # NOT SO SUPPORTED CONVERSION:
    # * regexp to (number|bool|strnum)
    # 	Always check the func retcode for consistent results.
    # * any type to regexp (for gawk's version <= 5.1.0, although
    #   the result may have some meaning, the destination type is a string).
    #   Always check the func retcode.
    # * A special case is forcing any type to unassigned or untyped,
    #   which indeed makes unassigned or untyped values but...
    #   always check the func retcode! Depending on the running
    #   gawk's version the new type can be one of the two,
    #   albeit operatively they can be used interchangeably.
    #   Versions prior 5.2 are expected to give the "unassigned" type.
    #
    # Again, always checks the function's return code to known
    # if the given result had any means.
    delete dest
    dest["val"] = val
    dest["val_type"] = awk::typeof(val)
    # default to unassigned|untyped:
    dest["newval"]
    dest["newval_type"]
    switch (type) {
	case "unassigned": case "untyped":
	    break
	case "string":
	    if (dest["val_type"] != "string")
		dest["newval"] = val ""
	    else
		dest["newval"] = val
	    break
        case "strnum":
	    if (dest["val_type"] == "unassigned" || dest["val_type"] == "untyped") {
		dest["newval"] = make_strnum(0)
	    } else {
		dest["newval"] = make_strnum(val)
		if (dest["newval"] != (make_strnum(val) + 0)) {
		    printf ("force_type: Cannot convert from <%s> to <%s> \n",
			    dest["val_type"], type) >> "/dev/stderr"
		    return 0
		}
	    }
	    break
        case "number":
	    if (dest["val_type"] == "number") {
		dest["newval"] = val
	    } else {
		# make a step to number...
		dest["newval"] = make_strnum(val)
		if (awk::typeof(dest["newval"]) != "strnum") {
		    printf ("force_type: Cannot convert from <%s> to <%s> \n",
			    dest["val_type"], type) >> "/dev/stderr"
		    return 0
		} else {
		    dest["newval"] = awk::strtonum(dest["newval"])
		}
	    }
	    break
	case "number|bool":
	    if (dest["val_type"] == "regexp") {
		dest["newval"] = cmkbool(make_strnum(val) + 0)
		if (dest["newval"] != cmkbool(make_strnum(val))) {
		    printf ("force_type: Cannot convert from <%s> to <%s> \n",
			    dest["val_type"], type) >> "/dev/stderr"
		    return 0
		}
	    } else if (dest["val_type"] == "number|bool") {
		dest["newval"] = val		
	    } else {
		dest["newval"] = cmkbool(val)
	    }
	    break
	case "regexp":
	    # NOTE: https://www.gnu.org/software/gawk/manual/gawk.html#Strong-Regexp-Constants
	    # regexp-typed variable creation on runtime doens't works on gawk 5.1.0, so trying
	    # to make a regex with <make_regex>'s default (<_make_regex), but need
	    # to *always* check return code. See the doc of <set_make_regex> for a realiable
	    # alternative to the default <_make_regex> function to be used with gawk version
	    # up to 5.2.2 (the first checked version where awkpot::_make_regex works).
	    if (dest["val_type"] == "regexp") {
		dest["newval"] = val
	    } else {
		dest["newval"] = make_regex(val)
	    }
	    break
        default:
	    printf ("force_type: Unknown conversion type <%s>\n", type) >> "/dev/stderr"
	    return 0
    }
    dest["newval_type"] = awk::typeof(dest["newval"])
    return (dest["newval_type"] == type)
}

###########
# BOOLEAN #
###########

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


#######
# SYS #
#######

function getline_or_die(filename, must_exit, arr,    r) {
    # Calls `getline' without arguments ($filename is used only
    # for the output in case of errors) and, if $must_exit is true,
    # exits using the set_end_exit() function if errors, otherwise
    # returns false. If the getline call succedes, returns true.
    # $arr is an array in which the getline's return code will be
    # saved ($arr is deleted first).
    delete arr
    r = (getline)
    arr[0] = r
    if (r < 0) {
	printf("Error reading <%s>\n", filename) >> "/dev/stderr"
	if (must_exit)
	    set_end_exit(1)
	else
	    return 0
    }
    return 1
}

function set_end_exit(rt) {
    # Sets the program's exit status to $rt, which must
    # be and integer in the range 0..128.
    # Bad $rt values causes a warning messagge and
    # the exit status set to 1.
    # After that, in both cases, calls the builtin exit causing
    # a jump to the END clause of the program (if any).
    # See https://www.gnu.org/software/gawk/manual/html_node/Exit-Statement.html
    # and https://www.gnu.org/software/libc/manual/html_node/Exit-Status.html
    # NOTE: to be used to break the program flow that have an END clause
    # Then, in the END clause, a call to <end_exit> make the program
    # exits with status $rt.
    if ((rt !~ /^[0-9]{1,3}$/) || (int(rt) < 0) || (int(rt) > 126)) {
	printf("set_end_exit: invalid exit code <%s>\n", rt) >> "/dev/stderr"
        __EXIT_REALLY = 1
        exit(__EXIT_REALLY)
    }
    __EXIT_REALLY = rt
    exit(rt)
}


function end_exit() {
    # Exits with the status set from a previous call
    # to <set_end_exit>, otherwise do nothing.
    if (check_assigned(__EXIT_REALLY))
     	exit(__EXIT_REALLY)
}


function exec_command(command, must_exit, status) {
    # Executes $command using the built-in system() function.
    # Returns true if command succedes, 0 if fail.
    # If $must_exit is true, exit with the $command return code.
    # $status is an optional one-element array in which, at index 0,
    # the command's exit status will be saved (deleted at function call).
    delete status
    if (! command) {
	printf("exec_command: <%s> invalid command\n", command) >> "/dev/stderr"
	return 0
    }
    if (0 != (ret = system(command))) {
	status[0] = ret
	printf ("exec_command: Error! <%s> exit status is: %d\n",
		command, ret) >> "/dev/stderr"
	if (must_exit)
	    exit(ret)
	else
	    return 0
    }
    status[0] = ret
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
    # $run_values is an optional array (deleted at function call) in which some
    # information of the executed command will be stored, the indexes are:
    # * output => command's stdout
    # * retcode => <getline> last return code
    # * errno => the ERRNO value, if errors occours, or false.
    delete run_values
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
	    printf ("run_command: Error executing <%s>. ERRNO: %d\n",
		    cmd, PROCINFO["errno"]) >> "/dev/stderr"
	    exit(PROCINFO["errno"])
	} else {
	    run_values["errno"] = PROCINFO["errno"]
	    return 0
	}
    }
    run_values["errno"] = ""
    return 1
}


function check_load_module(name, is_ext, exe,    cmd) {
    # Checks if the awk module or the extension $name
    # is available in the system. If $name is an extension
    # to load, the (optional) $is_ext parameter must be set to true.
    # $exe is a custom executable name to run.
    # Return true if it's, else 0.

    # For some reasons ARGV[0] is unreliable, see
    # https://www.gnu.org/software/gawk/manual/gawk.html#index-dark-corner-31
    # so we fall back to use a plain "awk" name if not provided.
    #
    #exe = ARGV[0] ? (match(ARGV[0], "awk") ? ARGV[0] : "awk") : "awk"
    if (! exe)
	exe = "awk"
    if (is_ext)
        cmd = sprintf("%s -l %s 'BEGIN {exit(0)}'", exe, name)
    else
        cmd = sprintf("%s -i %s 'BEGIN {exit(0)}'", exe, name)
    return exec_command(cmd)
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
	printf ("read_file_arr: Error reading <%s>. ERRNO: %d\n",
		filename, PROCINFO["errno"]) >> "/dev/stderr"
    close(filename)
}


########
# MISC #
########

function set_sort_order(sort_type,    prev_sorted) {
    # Sets PROCINFO["sorted_in"] to $sort_type
    # Returns the previously sorting order string set.
    @dprint(sprintf("set_sort_order: actual sorting: <%s>", PROCINFO["sorted_in"]))
    prev_sorted = PROCINFO["sorted_in"]
    PROCINFO["sorted_in"] = sort_type
    @dprint(sprintf("set_sort_order: new sorting: <%s>", PROCINFO["sorted_in"]))
    return prev_sorted
}

function random(seed, upto, init,    __rarr, __u, __i) {
    # Convenience function to generate pseudo-random numbers
    # using some builtin functions.
    # $seed is a positive integer used (if $init is true) to initialize
    # the random number generator (otherwise systime() is used).
    # $upto (default to 1e6) is the upper limit of the
    # generated number (from 0 to $upto - 1).
    # To get random numbers call this function a first time as
    #
    # random(0, 0, 1)
    #
    # to set a casual seed, then call random() without arguments
    # to get random values. Giving the same value to $seed
    # assures predictable sequence from run to run.
    if (! upto)
	upto = 1e6
    if (! seed)
	seed = awk::systime() % 1000
    if (init)
        srand(seed)
    return int(upto * rand())
}


BEGIN {
    set_dprint("awkpot::dprint_fake")
    set_mkbool()
    __make_regex = "awkpot::_make_regex"
}

