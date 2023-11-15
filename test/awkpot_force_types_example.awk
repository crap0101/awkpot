
# Run this to show the behaviour of the running gawk
# about type-forcing values.

@include "awkpot"

BEGIN {
    split("1", arr, ":")
    arr[0] = 11
    arr[2] = "bar"
    arr[3] = @/^x.*?$/
    arr[33] = @/1/
    arr[4]
    arr[5] = "12"
    arr[55] = ""
    if (awkpot::check_defined("mkbool"))
	arr[6] = awkpot::cmkbool(0)
    to_force[0] = "number"
    to_force[10] = "strnum"
    to_force[110] = "string"
    to_force[1110] = "regexp"
    to_force[11110] = "unassigned"
    to_force[20] = "untyped"
    if (awkpot::check_defined("mkbool"))
	to_force[120] = "number|bool"
    for (i in arr) {
        for (j in to_force) {
            r = awkpot::force_type(arr[i], to_force[j], forced)
	    printf("<%s> (%s) [to %s: %s] ==> <%s> (%s)\n",
		   arr[i], typeof(arr[i]), to_force[j], r ? "OK": "FAIL", forced["newval"], forced["newval_type"])
	}
	print "=========="
    }
}
