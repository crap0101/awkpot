====================
=== DESCRIPTION  ===
====================

awkpot: miscellaneous utilities for (g)awk

Defines namespace "awkpot"

===============
== FUNCTIONS ==
===============

dprint_fake(arg)
    Does nothing, and returns false.

dprint_real(arg)
    Prints arg on stderr, for real!
    Return true.

set_dprint(arg)
    Sets @dprint function to $arg.
    awkpot provides <dprint_fake> (print nothing)
    and <dprint_real> for printing to sderr.

get_fmt(str, conv, maxspace, position)
    Given a string $str and a conversion specifier $conv optionally
    with a precision field (like "d", "u", ".2f", etc... default to "s")
    builds a format string suitable to be used with (s)printf
    for print $str in a space of $maxspace chars justified
    as per $position, which must be one of "<c>":
    "<" means justify to the left,
    "c" means centered,
    ">" means justify to the right.
    If $maxspace < 1, returns the format string without any padding.

join(arr, sep, order)
    Returns a string with the values or the $arr array joined
    with the optional $sep separator (default "").
    Array traversal can be controlled by the $order
    parameter, a valid PROCINFO["sorted_in"] string
    (default to "", keep the actual sortig order).
    NOTE: works on flatten arrays only, any subarrays will cause a fatal error.
    If you need advanced array's features see the arrlib's functions at:
    https://github.com/crap0101/awk_arrlib

join_range(arr, first, last, sep, order)
    Like awkpot::join but only for elements in the $fist..$last range
    (starting from 1) of the array traversal. Values < 1 for $first are
    treated as 1, and for $last are treated as the $arr length.

make_escape(s)
    Returns a printable form of the $s escape sequence string.
    NOT all escaped sequences are covered as far, only
    the most userful (we hope).
    Proper $s values are:
    "\0", "\n", "\a", "\b", "\f", "\r", "\t", "\v".
    If $s is not one of them, $s itself will be returned.
    NOTE (rational): the need of this function arise from the behaviour
    within argument passing of those escape sequences to (g)awk programs
    using, for example, the builtin getopt module, i.e. NOT using
    the -v var=YYY switch NOR having this strings harcoded in the
    programs text AND want to use them in the non literal form,
    for example when setting ORS of OFS.

make_printable(s)
    Shortcut for get a copy os $s with
    printable sequences (if any), using make_escape.
    Supported escapes are: \0, \a, \b, \f,\n, \r, \t, \v.

escape(s)
    Escapes some tokens (<"> and <\>) of the string $s.
    Designed for formatting program's help() strings
    readed from a plain text file.

startswith(str, start)
    Returns true if $str starts with $start, else false.

endswith(str, end)
    Returns true if $str ends in $end, else false.

strrepeat(str, count, sep)
    Returns $str joined $count times with itself,
    optionally separated by $sep.
    If count < 2 returns $str.

make_array_record(arr)
    Puts the fields of the current record in $arr, deleting it first.
    Returns the number of elements (NF).
    NOTE: clone of the same arrlib's function,
    just copied here for the semplicity.

get_record_string(first, last,   t, arr, seps)
    Rebuilds the current record, optionally from the $first field
    to the $last field (default to the entire record).
    Values < 1 for $first are treated as 1, and for $last are
    treated as the record's number of fields.
    Returns the resulting string.

cmp_version(v1, v2, cmp, major, minor, patch)
    5.2.0 min for mkbool
    Compares the two (g)awk version string $v1 and $v2
    using the $cmp function (indirect call) which must
    returns true if the two arguments compares equal.
    $major, $minor and $patch can be sets to a true value
    for comparing only the given part of the version number.
    If $v1 is false gets the in-use gawk version.
    Returns true if $v1 and $v2 compares equal, false otherwise.

eq(a, b)
    Returns true if $a equal $b, else false.

ne(a, b)
    Returns true if $a not equal $b, else false.

gt(a, b)
    Returns true if $a is greater than $b, else false.

ge(a, b)
    Returns true if $a is greater or equal $b, else false.

lt(a, b)
    Returns true if $a is less than $b, else false.

le(a, b)
    Returns true if $a is less than or equal $b, else false.

cmp(a, b, f)
    Bare-bones comparison function, see <compare> for a
    more generic comparison function.
    Compares $a and $b using the function $f, which must takes two
    arguments and returns a true value if succedes, false otherwise.
    If $f is not provided or evaluates to false, uses the
    awkpot::eq function instead.
    Returns the result of $f($a, $b).

make_regex(val)
    Calls the set __make_regex func.

_make_regex(val)
    Returns a regexp-typed
    variable from the value $val.
    If fails creating the regex value, returns "unassigned".
    NOTE: works in gawk >= 5.2.2
    For older version, see
    the <make> function @ https://github.com/crap0101/awk_regexmix 

set_make_regex(f)
    Set the provided $f function (which must takes *one* argument
    and returns a regex-typed value) to the one to be used
    instead to the default <make_regex> function, which doesn't works
    on gawk versions <= 5.2.2 (the sub() trick doesn't works, instead of a
    regexp value a string is returned).
    A possible $f candidate can be
    the <make> function @ https://github.com/crap0101/awk_regexmix

get_make_regex()
    Returns the current function used by <make_regex>

make_strnum(val)
    Returns a strnum-typed variable for the value $val,
    if can be interpreted as a numeric string.
    See https://www.gnu.org/software/gawk/manual/gawk.html#String-Type-versus-Numeric-Type

id(x)
    Identity function.

len(x)
    Returns the length of $x using the builtin length() function.
    NOTE: workaround for a bug in gawk version < 5.3.0 (at list in gawk 5.1.0)
    when using the builtin's <length> function as indirect function call.
    Should be used - for example - as the 2nd parameter
    of the arrlib::max_val function.

check_assigned(name)
    Returns true if $name already got a value,
    false if untyped or unassigned.

check_defined(funcname, check_id)
    Checks if $funcname is available, searching
    in the FUNCTAB array.
    If $check_id is true, check also the
    PROCINFO["identifiers"] array.
    In the latter case, can be used to check any other names.

equals(val1, val2, type)
    Checks if $val1 equals $val2.
    Arrays comparison (array vs array, array vs scalar)
    evaluate always to false. (use arrlib::equal to compare arrays).
    If $type is true, checks also if the values are of the same type.

equals_typed(val1, val2)
    Checks if $val1 equals $val2 and are both of the same type.
    Not meant to be used directly (use the <equals> funcs with
    the $type parameter, instead).

force_type(val, type, dest)
    Tries to force the type of $val to $type mantaining the $val's meaning.
    Saves conversion and other infos in the $dest array.
    $dest array's elements are indexed as follow:
    * "val" is the value passed to the function
    * "val_type" is the $val type as per typeof()
    * "newval" is the value after the tentative type coercion
    * "newval_type" is the "newval"'s type, as per the $type argument.
    Returns 1 if the conversion succeeded or 0 if errors.
    #
    SUPPORTED $val types:
    * string, number, number|bool, strnum, regexp, unassigned, untyped
    SUPPORTED $type values:
    * string, number, regexp, number|bool, strnum, unassigned, untyped
    #
    NOTE: $type bool require a (g)awk version with the builtin
    mkbool function. In sostitution the awkpot::set_mkbool
    function can be used to set the custom _mkbool in his place,
    however the returned value will be of type "number").
    #
    NOT SO SUPPORTED CONVERSION:
    * regexp to (number|bool|strnum)
    Always check the func retcode for consistent results.
    * any type to regexp (for gawk's version <= 5.1.0, although
    the result may have some meaning, the destination type is a string).
    Always check the func retcode.
    * A special case is forcing any type to unassigned or untyped,
    which indeed makes unassigned or untyped values but...
    always check the func retcode! Depending on the running
    gawk's version the new type can be one of the two,
    albeit operatively they can be used interchangeably.
    Versions prior 5.2 are expected to give the "unassigned" type.
    #
    Again, always checks the function's return code to known
    if the given result had any means.

_mkbool(expression)
    Private function for "creating" bool values.
    Returns 1 if $expression evaluate to a true value, else 0.
    For (g)awk version without the mkbool function.

cmkbool(expression)
    Returns true if $expression evaluate to a true value, else false.
    For (g)awk version without the mkbool function.
    Uses either awkpot::_mkbool or,
    if available, the builtin mkbool function.

set_mkbool()
    Checks and set a sort-of-a-kind "mkbool" function.
    For (g)awk version without the builtin mkbool function,
    sets the function used by cmkbool (awkpot::_mkbool function),
    otherwise uses the builtin mkbool function.
    Returns a string of the setted name.

getline_or_die(filename, must_exit, arr)
    Calls `getline' without arguments ($filename is used only
    for the output in case of errors) and, if $must_exit is true,
    exits using the set_end_exit() function if errors, otherwise
    returns false. If the getline call succedes, returns true.
    $arr is an array in which the getline's return code will be
    saved (at index 0, also note $arr is deleted at function call).

set_end_exit(rt)
    Sets the program's exit status to $rt, which must be
    an integer in the range 0..128.
    Bad $rt values causes a warning messagge and the exit status set to 1.
    After that, in both cases, calls the builtin exit causing
    a jump to the END clause of the program (if any).
    See https://www.gnu.org/software/gawk/manual/html_node/Exit-Statement.html
    and https://www.gnu.org/software/libc/manual/html_node/Exit-Status.html
    NOTE: to be used to break the program flow that have an END clause
    Then, in the END clause, a call to <end_exit> make the program
    exits with status $rt.

end_exit()
    Exits with the status set from a previous call
    to <set_end_exit>, otherwise do nothing.

exec_command(command, must_exit, status)
    Executes $command using the built-in system() function.
    Returns true if command succedes, 0 if fail.
    If $must_exit is true, exit with the $command return code.
    $status is an optional one-element array in which, at index 0,
    the command's exit status will be saved (deleted at function call).

run_command(command, nargs, args_array, must_exit, run_values)
    Alternative method to run a command using <getline>,
    purposely avoiding the built-in system() function (see exec_command).
    #
    Runs $command with arguments retrieved from $args_array.
    The latter must be a zero-based indexed array filled with $nargs number
    of arguments, used to build the command line to execute.
    If any errors occours during the command executions *and* must_exit is
    true, exits with ERRNO value, otherwise returns 0. If everything
    gone well, returns 1.
    $run_values is an optional array (deleted at function call) in which some
    information of the executed command will be stored, the indexes are:
    * output => command's stdout
    * retcode => <getline> last return code
    * errno => the ERRNO value, if errors occours, or false.

check_load_module(name, is_ext, exe)
    Checks if the awk module or the extension $name is available in the system.
    If $name is an extension to load, the (optional) $is_ext parameter must
    be set to true. $exe is a custom executable name to run (default to "awk").
    Return true if it's, else 0.

read_file_arr(filename, dest, start_index)
    Reads $filename into the $dest array, one line per index
    starting from $start_index (optional, default to 0).

set_sort_order(sort_type)
    Sets PROCINFO["sorted_in"] to $sort_type
    Returns the previously sorting order string set.

random(seed, upto, init)
    Convenience function to generate pseudo-random numbers
    using some builtin functions.
    $seed is a positive integer used (if $init is true) to initialize
    the random number generator (otherwise systime() is used).
    $upto (default to 1e6) is the upper limit of the
    generated number (from 0 to $upto - 1).
    To get random numbers call this function a first time as
    #
    # random(0, 0, 1)
    #
    to set a casual seed, then call random() without arguments
    to get random values. Giving the same value to $seed
    assures predictable sequence from run to run.
