
@include "awkpot"
@include "arrlib"
# https://github.com/crap0101/awk_arrlib
@include "testing"
# https://github.com/crap0101/awk_testing

@load "sysutils"
# https://github.com/crap0101/awk_sysutils
@load "regexmix"
# https://github.com/crap0101/awk_regexmix

# NOTES:
# * Some tests uses system's commands: which, seq, awk        # :D
# and some non-standard ones:  _____x__foo, xx_foo__bar__xx   # ^|^
# * Others requires the sysutils extension (see some lines above).

BEGIN {
   if (awk::AWKPOT_DEBUG) {
	dprint = "awkpot::dprint_real"
	# to set dprint in awkpot functions also (defaults to dprint_fake)
	awkpot::set_dprint(dprint)
    } else {
	dprint = "awkpot::dprint_fake"
    }

    testing::start_test_report()

    t = sys::mktemp("/tmp")

    cmd = "seq"
    args[0] = 4
    args[1] = 20
    args[2] = sprintf("> %s", t)
    ret = awkpot::run_command(cmd, 3, args, 0, run)
    testing::assert_true(ret, 1, "> run_command()")
    testing::assert_equal(run["retcode"], 0, 1, "> run_command retcode == 0")
    testing::assert_false(run["errno"], "", 1, "> ! run_command ERRNO")
    testing::assert_false(run["output"], "", 1, "> ! run_command output (redirected)")

    awkpot::read_file_arr(t, arread, 4)
    for (i=args[0]; i<=args[1]; i++)
	arread2[i] = i
    testing::assert_true(arrlib::equals(arread, arread2), 1, "> (equals) arread")

    delete args[2]
    delete run
    ret = awkpot::run_command(cmd, 2, args, 0, run)
    testing::assert_true(ret, 1, "> run_command()")
    testing::assert_equal(run["retcode"], 0, 1, "> run_command retcode == 0")
    testing::assert_false(run["errno"], "", 1, "> ! run_command ERRNO")

    awkpot::read_file_arr(t, arread, 4)
    s_arr = arrlib::sprintf_vals(arread, "\n")
    s_arr = s_arr "\n" # append a newline cuz run_command outputs this way
    testing::assert_equal(run["output"], s_arr, 1, "> run_command output == (sprintf_vals) arread")
    delete arread
    
    # TEST dprint_real, dprint_fake, 
    @dprint("* test dprint_real / dprint_fake:")
    f = "awkpot::dprint_real"
    cmd = sprintf("awk -i awkpot.awk 'BEGIN {%s(\"foo\")}' 2>%s", f, t)
    ret = awkpot::run_command(cmd, 0, args, 0, run)
    awkpot::read_file_arr(t, arread)
    testing::assert_equal("foo", arread[0], 1, "> dprint to stderr")
    delete arread
    
    f = "awkpot::dprint_fake"
    cmd = sprintf("awk -i awkpot.awk 'BEGIN {%s(\"foo\")}' 2>%s", f, t)
    ret = awkpot::run_command(cmd, 0, args)
    awkpot::read_file_arr(t, arread)
    testing::assert_equal(0, arrlib::array_length(arread), 1, "> dprint fake (length)")
    testing::assert_equal("", arrlib::sprintf_vals(arread), 1, "> dprint fake (sprintf)")
    testing::assert_true(arrlib::is_empty(arread), 1, "> dprint fake (is_empty)")
    delete arread

    # TEST set_dprint
    @dprint("* test set_dprint:")
    cmd = sprintf("awk -i awkpot.awk 'BEGIN {awkpot::set_dprint(\"awkpot::dprint_real\");awkpot::set_sort_order(\"fake\")}' 2>%s", t)
    ret = awkpot::run_command(cmd, 0, args)
    awkpot::read_file_arr(t, arread)
    @dprint("* arread:") && arrlib::printa(arread)
    testing::assert_not_equal(0, arrlib::array_length(arread), 1, "> set_dprint (real) (length)")
    testing::assert_equal(2, arrlib::array_length(arread), 1, "> set_dprint (real) (length eq)")
    testing::assert_not_equal("", arrlib::sprintf_vals(arread), 1, "> set_dprint (real) (sprintf !eq)")
    delete arread
    sys::rm(t)

    sys::rm(t)
    
    # TEST set_sort_order
    @dprint("* test sort_order:")
    ord[0] = PROCINFO["sorted_in"]
    ord[1] = "@val_type_asc"
    ord[2] = "@ind_str_desc"
    ord[3] = "@val_type_desc"
    for (i=0; i<3; i++) {
	prev = awkpot::set_sort_order(ord[i+1])
	testing::assert_equal(prev, ord[i],
			      1, sprintf("> set_sort_order (check prev=%s)", prev ? prev : "{empty}"))
	testing::assert_equal(PROCINFO["sorted_in"], ord[i+1],
			      1, sprintf("> set_sort_order (check PROCINFO=%s)", ord[i+1]))
    }
    awkpot::set_sort_order(ord[0])

    # TEST equals
    @dprint("* test equals:")
    testing::assert_true(awkpot::equals("foo", "foo"), 1, "> equals \"foo\" \"foo\"")
    testing::assert_true(awkpot::equals("foo", @/foo/), 1, "> ! equals \"foo\" @/foo/")
    testing::assert_false(awkpot::equals("foo", @/foo/, 1), 1, "> ! equals (t) \"foo\" @/foo/")
    testing::assert_true(awkpot::equals(1, 1), 1, "> equals 1 1")
    testing::assert_true(awkpot::equals(1, 1, 1), 1, "> equals (t) 1 1")
    testing::assert_true(awkpot::equals(1, "1"), 1, "> equals 1 \"1\"")
    testing::assert_false(awkpot::equals(1, "1", 1), 1, "> ! equals (t) 1 \"1\"")
    testing::assert_false(awkpot::equals(0, ""), 1, "> equals 0 \"\"")
    testing::assert_false(awkpot::equals(0, "", 1), 1, "> equals (t) 0 \"\"")
    
    arr1[0] = 1 ; arr1[1] = 1
    arr2[0] = 10 ; arr2[1] = 11
    arr3[11] = 1 ; arr3[10] = 0
    testing::assert_true(awkpot::equals(arr1, arr2), 1, "> equals arr1 arr2")
    testing::assert_true(awkpot::equals(arr3, arr2), 1, "> equals arr3 arr2")
    @dprint("* delete arr1")
    delete arr1
    testing::assert_true(awkpot::equals(arr1, arr3), 1, "> equals arr1 arr3")
    testing::assert_false(awkpot::equals("foo", arr3), 1, "> ! equals \"foo\" arr3")
    testing::assert_false(awkpot::equals("foo", "foo "), 1, "> ! equals \"foo\" \"foo \"")

    # TEST equals_typed
    @dprint("* test equals_typed:")
    testing::assert_equal(awkpot::equals(1, 1), awkpot::equals_typed(1, 1), 1, "> equals/typed 1 1")
    testing::assert_not_equal(awkpot::equals(1, "1"), awkpot::equals_typed(1, "1"), 1, "> ! equals/typed 1 \"1\"")
    testing::assert_equal(awkpot::equals(1, "1", 1), awkpot::equals_typed(1, "1"), 1, "> equals+t/typed 1 \"1\"")
    testing::assert_equal(awkpot::equals(0, ""), awkpot::equals_typed(0, ""), 1, "> equals/typed 0 \"\"")
    testing::assert_equal(awkpot::equals(0, "", 1), awkpot::equals_typed(0, ""), 1, "> ! equals/typed 0 \"\"")

    # TEST id
    testing::assert_equal(awkpot::id(2), 2, 1, "> id 2 2")
    testing::assert_equal(awkpot::id(0), 0, 1, "> id 0 0")
    testing::assert_equal(awkpot::id("foo"), "foo", 1, "> id foo foo")
    testing::assert_equal(awkpot::id(""), "", 1, "> id ~empty~")

    # TEST len
    testing::assert_true(awkpot::equals(awkpot::len("foo"), length("foo")), 1, "> len foo foo")
    testing::assert_true(awkpot::equals(awkpot::len(""), length("")), 1, "> len ~empty~")
    testing::assert_true(awkpot::equals(awkpot::len("f"), length("f")), 1, "> len f f")

    # TEST check_assigned
    testing::assert_false(awkpot::check_assigned(yyyyyyyyyyyyyyyyyyyyy), 1, "> ! check_assigned")
    testing::assert_false(awkpot::check_assigned(yyyyyyyyyyyyyyyyyyyyy), 1, "> ! check_assigned (again)")
    yyyyyyyyyyyyyyyyyyyyy = 0
    testing::assert_true(awkpot::check_assigned(yyyyyyyyyyyyyyyyyyyyy), 1, "> check_assigned")
    
    # TEST check_defined
    @dprint("* test check_defined:")
    testing::assert_true(awkpot::check_defined("split"), 1, "> check_defined(\"split\")")
    testing::assert_true(awkpot::check_defined("awkpot::check_defined"), 1, "> check_defined(\"check_defined\")")
    testing::assert_nothing(awkpot::check_defined("mkbool"), 0, "> check_defined(\"mkbool\")")
    testing::assert_true(awkpot::check_defined("awkpot::cmkbool"), 1, "> check_defined(\"cmkbool\")")
    testing::assert_false(awkpot::check_defined("awkpot::_cmkbool"), 1, "> ! check_defined(\"_cmkbool\")")
    testing::assert_true(awkpot::check_defined("awkpot::_cmkbool", 1), 1, "> check_defined(\"_cmkbool\", 1)")

    # NOTE: even re-calling set_mkbool, PROCINFO["identifiers"] is not updated
    #@dprint("* delete awkpot::_cmkbool")
    #delete PROCINFO["identifiers"]["awkpot::_cmkbool"]
    #testing::assert_false(awkpot::check_defined("awkpot::_cmkbool", 1), 1, "> check_defined(\"_cmkbool\", 1)")

    @dprint("* set_mkbool");
    bool_f = awkpot::set_mkbool()
    testing::assert_false(awkpot::check_defined("awkpot::_cmkbool"), 1, "> ! check_defined(\"_cmkbool\")")
    testing::assert_true(awkpot::check_defined("awkpot::_cmkbool", 1), 1, "> check_defined(\"_cmkbool\", 1)")
    testing::assert_true(bool_f, 1, "bool_f name set")
    testing::assert_true((bool_f == "mkbool" || bool_f == "awkpot::_mkbool"), 1, "bool_f func name")
    
    # set cmkbool / _mkbool
    @dprint("* test cmkbool / _mkbool:")
    mkboolarr_false[0]=""
    mkboolarr_false[1]=0
    mkboolarr_false[2]
    mkboolarr_true[0]="foo"
    mkboolarr_true[1]="0"
    mkboolarr_true[2]=@/^baz?/
    mkboolarr_true[3]=1
    for (i in mkboolarr_false) {
	testing::assert_false(awkpot::_mkbool(mkboolarr_false[i]), 1, sprintf("> ! _mkbool(<%s>) [%s]", mkboolarr_false[i], i))
	testing::assert_false(awkpot::cmkbool(mkboolarr_false[i]), 1, sprintf("> ! cmkbool(<%s>) [%s]", mkboolarr_false[i], i))
    }
    for (i in mkboolarr_true) {
	testing::assert_true(awkpot::_mkbool(mkboolarr_true[i]), 1, sprintf("> _mkbool(<%s>) [%s]", mkboolarr_true[i], i))
	testing::assert_true(awkpot::cmkbool(mkboolarr_true[i]), 1, sprintf("> cmkbool(<%s>) [%s]", mkboolarr_true[i], i))
    }
    testing::assert_equal(awkpot::cmkbool(0), awkpot::cmkbool(""), 1, "> cmkbool 0 \"\"")
    testing::assert_equal(awkpot::cmkbool(mkboolarr_false[2]), awkpot::cmkbool(""), 1, "> cmkbool undefined \"\"")

    # TEST force_type
    delete arr
    #print awkpot::check_defined("mkbool")
    split("foo:2,3", str_arr, ":")

    split("1:2.3:1e2", strnum_arr, ":")
    strnum_arr[23]

    num_arr[0]=0
    num_arr[1]=11
    num_arr[2]=1e2
    num_arr[3]
    
    reg_arr[0] = @/^foo/
    reg_arr[1] = @/1/
    @dprint("* test force_type:")

    # empty string:
    testing::assert_true(awkpot::force_type("", "number", force_arr),
			 1, sprintf("> force_type <%s> (<%s>) to number", "", awk::typeof("")))
    testing::assert_equal(force_arr["newval_type"], "number", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
    # unassigned:
    _str_arr[22]
    testing::assert_true(awkpot::force_type(_str_arr[22], "number", force_arr),
			 1, sprintf("> force_type <%s> (<%s>) to number", _str_arr[22], awk::typeof(_str_arr[22])))
    testing::assert_equal(force_arr["newval_type"], "number", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))

    for (i in str_arr) {
	testing::assert_true(awkpot::force_type(str_arr[i], "string", force_arr),
			     1, sprintf("> force_type <%s> (<%s>) to string", str_arr[i], awk::typeof(str_arr[i])))
	testing::assert_equal(force_arr["newval_type"], "string", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	@dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))
	# NOTE_1: gives unassigned in gawk version < 5.2.2 (using the default awkpot::_make_regex function)
	if (awkpot::cmp_version(awkpot::get_version(), "5.2.2", "awkpot::lt")) {
	    testing::assert_false(awkpot::force_type(str_arr[i], "regexp", force_arr),
				  1, sprintf("> ! force_type <%s> (<%s>) to regex", str_arr[i], awk::typeof(str_arr[i])))
	    testing::assert_equal(force_arr["newval_type"], "unassigned", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	} else {
	    testing::assert_true(awkpot::force_type(str_arr[i], "regexp", force_arr),
				 1, sprintf("> ! force_type <%s> (<%s>) to regex", str_arr[i], awk::typeof(str_arr[i])))
	    testing::assert_equal(force_arr["newval_type"], "regexp", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	}
	@dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))

	testing::assert_false(awkpot::force_type(str_arr[i], "number", force_arr),
			     0, sprintf("> ! force_type <%s> (<%s>) to number", str_arr[i], awk::typeof(str_arr[i])))
	testing::assert_not_equal(force_arr["newval_type"], "number", 0, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	@dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))
	# for gawk without mkbool, force_type will return false...
	if (! awkpot::check_defined("mkbool")) {
	    testing::assert_false(awkpot::force_type(str_arr[i], "number|bool", force_arr),
				  1, sprintf("> force_type <%s> (<%s>) to bool", str_arr[i], awk::typeof(str_arr[i])))
	    testing::assert_not_equal(force_arr["newval_type"], "number|bool", 0, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	} else {
	    testing::assert_true(awkpot::force_type(str_arr[i], "number|bool", force_arr),
				 1, sprintf("> force_type <%s> (<%s>) to bool", str_arr[i], awk::typeof(str_arr[i])))
	    testing::assert_equal(force_arr["newval_type"], "number|bool", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	}
	@dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))
    }

    for (i in strnum_arr) {
	# NOTE_1: gives unassigned in gawk version < 5.2.2 (using the default awkpot::_make_regex function)
	if (awkpot::cmp_version(awkpot::get_version(), "5.2.2", "awkpot::lt")) {
	    testing::assert_false(awkpot::force_type(strnum_arr[i], "regexp", force_arr),
				  1, sprintf("> ! force_type <%s> (<%s>) to regexp", strnum_arr[i], awk::typeof(strnum_arr[i])))
	    testing::assert_equal(force_arr["newval_type"], "unassigned", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	} else {
	    testing::assert_true(awkpot::force_type(strnum_arr[i], "regexp", force_arr),
				  1, sprintf("> ! force_type <%s> (<%s>) to regexp", strnum_arr[i], awk::typeof(strnum_arr[i])))
	    testing::assert_equal(force_arr["newval_type"], "regexp", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	}
	@dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))
	testing::assert_true(awkpot::force_type(strnum_arr[i], "number", force_arr),
			     1, sprintf("> force_type <%s> (<%s>) to number", strnum_arr[i], awk::typeof(strnum_arr[i])))
	testing::assert_equal(force_arr["newval_type"], "number", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	@dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))
	# for gawk without mkbool, force_type will return false...
	if (! awkpot::check_defined("mkbool")) {
	    testing::assert_false(awkpot::force_type(strnum_arr[i], "number|bool", force_arr),
				  1, sprintf("> force_type <%s> (<%s>) to bool", strnum_arr[i], awk::typeof(strnum_arr[i])))
	    testing::assert_equal(force_arr["newval_type"], "number", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	} else {
	    testing::assert_true(awkpot::force_type(strnum_arr[i], "number|bool", force_arr),
				 1, sprintf("> force_type <%s> (<%s>) to bool", strnum_arr[i], awk::typeof(strnum_arr[i])))
	    testing::assert_equal(force_arr["newval_type"], "number|bool", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	}
	@dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))
    }

    for (i in num_arr) {
	# NOTE_1: gives unassigned in gawk version < 5.2.2 (using the default awkpot::_make_regex function)
	if (awkpot::cmp_version(awkpot::get_version(), "5.2.2", "awkpot::lt")) {
	    testing::assert_false(awkpot::force_type(num_arr[i], "regexp", force_arr),
			     1, sprintf("> ! force_type <%s> (<%s>) to regexp", num_arr[i], awk::typeof(num_arr[i])))
	    testing::assert_equal(force_arr["newval_type"], "unassigned", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	} else {
	    testing::assert_true(awkpot::force_type(num_arr[i], "regexp", force_arr),
			     1, sprintf("> ! force_type <%s> (<%s>) to regexp", num_arr[i], awk::typeof(num_arr[i])))
	    testing::assert_equal(force_arr["newval_type"], "regexp", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	}
	@dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))
	testing::assert_true(awkpot::force_type(num_arr[i], "number", force_arr),
			     1, sprintf("> force_type <%s> (<%s>) to number", num_arr[i], awk::typeof(num_arr[i])))
	testing::assert_equal(force_arr["newval_type"], "number", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	@dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))
	# for gawk without mkbool, force_type will return false...
	if (! awkpot::check_defined("mkbool")) {
	    testing::assert_true(awkpot::force_type(num_arr[i], "number", force_arr),
				    1, sprintf("> force_type <%s> (<%s>) to bool", num_arr[i], awk::typeof(num_arr[i])))
	    testing::assert_equal(force_arr["newval_type"], "number", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	} else {
	    testing::assert_true(awkpot::force_type(num_arr[i], "number|bool", force_arr),
				 1, sprintf("> force_type <%s> (<%s>) to bool", num_arr[i], awk::typeof(num_arr[i])))
	    testing::assert_equal(force_arr["newval_type"], "number|bool", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	}
	@dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))
    }

    # reg_arr:
    testing::assert_true(awkpot::force_type(reg_arr[0], "string", force_arr),
			 1, sprintf("> force_type <%s> (<%s>) to string", reg_arr[0], awk::typeof(reg_arr[0])))
    testing::assert_equal(force_arr["newval_type"], "string", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
    @dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
		    force_arr["val"], force_arr["newval"], force_arr["newval_type"]))
    testing::assert_true(awkpot::force_type(reg_arr[0], "regexp", force_arr),
			 1, sprintf("> force_type <%s> (<%s>) to regexp", reg_arr[0], awk::typeof(reg_arr[0])))
    testing::assert_equal(force_arr["newval_type"], "regexp", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
    @dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
		    force_arr["val"], force_arr["newval"], force_arr["newval_type"]))
    testing::assert_false(awkpot::force_type(reg_arr[0], "number", force_arr),
			  1, sprintf("> ! force_type <%s> (<%s>) to number", reg_arr[0], awk::typeof(reg_arr[0])))
    @dprint(sprintf("* (failed) forcing <%s> gets <%s> (type: <%s>)",
		    force_arr["val"], force_arr["newval"], force_arr["newval_type"]))
    testing::assert_false(awkpot::force_type(reg_arr[0], "number|bool", force_arr),
			  1, sprintf("> ! force_type <%s> (<%s>) to bool", reg_arr[0], awk::typeof(reg_arr[0])))
    @dprint(sprintf("* (failed) forcing <%s> gets <%s> (type: <%s>)",
		    force_arr["val"], force_arr["newval"], force_arr["newval_type"]))
    testing::assert_true(awkpot::force_type(reg_arr[1], "string", force_arr),
			 1, sprintf("> force_type <%s> (<%s>) to string", reg_arr[1], awk::typeof(reg_arr[1])))
    testing::assert_equal(force_arr["newval_type"], "string", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
    @dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
		    force_arr["val"], force_arr["newval"], force_arr["newval_type"]))
    testing::assert_true(awkpot::force_type(reg_arr[1], "regexp", force_arr),
			 1, sprintf("> force_type <%s> (<%s>) to regexp", reg_arr[1], awk::typeof(reg_arr[1])))
    testing::assert_equal(force_arr["newval_type"], "regexp", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
    @dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
		    force_arr["val"], force_arr["newval"], force_arr["newval_type"]))
    testing::assert_true(awkpot::force_type(reg_arr[1], "number", force_arr),
			  1, sprintf("> force_type <%s> (<%s>) to number", reg_arr[1], awk::typeof(reg_arr[1])))
    if (! awkpot::check_defined("mkbool")) {
	testing::assert_false(awkpot::force_type(reg_arr[1], "number|bool", force_arr),
			      1, sprintf("> force_type <%s> (<%s>) to bool", reg_arr[1], awk::typeof(reg_arr[1])))
	testing::assert_equal(force_arr["newval_type"], "number", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
    } else {
	testing::assert_true(awkpot::force_type(reg_arr[1], "number|bool", force_arr),
			     0, sprintf("> force_type <%s> (<%s>) to bool", reg_arr[1], awk::typeof(reg_arr[1])))
	testing::assert_equal(force_arr["newval_type"], "number|bool", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
    }
    @dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
		    force_arr["val"], force_arr["newval"], force_arr["newval_type"]))

    # force unassigned / untyped
    # no arr element
    if (awkpot::cmp_version(awkpot::get_version(), "5.2.2", "awkpot::lt")) {
	testing::assert_true(awkpot::force_type(awkpot::id(yyyyyyyyyyyy), "unassigned", force_arr),
			     1, sprintf("> force_type <%s> (<%s>) to unassigned", "yyyyyyyyyyyy", awk::typeof(yyyyyyyyyyyy)))
	testing::assert_equal(force_arr["newval_type"], "unassigned",
			      1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	testing::assert_false(awkpot::force_type(awkpot::id(yyyyyyyyyyyyz), "untyped", force_arr),
			     1, sprintf("> ! force_type <%s> (<%s>) to untyped", "yyyyyyyyyyyyz", awk::typeof(yyyyyyyyyyyyz)))
	testing::assert_equal(force_arr["newval_type"], "unassigned",
			      1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	@dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))
    } else {
	testing::assert_true(awkpot::force_type(awkpot::id(yyyyyyyyyyyyx), "untyped", force_arr),
			     1, sprintf("> force_type <%s> (<%s>) to untyped", "yyyyyyyyyyyyx", awk::typeof(yyyyyyyyyyyyx)))
	testing::assert_equal(force_arr["newval_type"], "untyped",
			      1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	testing::assert_false(awkpot::force_type(awkpot::id(yyyyyyyyyyyyxx), "unassigned", force_arr),
			     1, sprintf("> ! force_type <%s> (<%s>) to unassigned", "yyyyyyyyyyyyxx", awk::typeof(yyyyyyyyyyyyxx)))
	testing::assert_equal(force_arr["newval_type"], "untyped",
			      1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	@dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))
    }

    delete __arr
    split("2.3", __arr, ":")
    __arr[0] = @/^foo/
    __arr[2]=1e2
    __arr[3]
    __arr[4] = "foo"
    for (i in __arr) {
	if (awkpot::cmp_version(awkpot::get_version(), "5.2.2", "awkpot::lt")) {
	    testing::assert_true(awkpot::force_type(__arr[i], "unassigned", force_arr),
				 1, sprintf("> force_type <%s> (<%s>) to unassigned", __arr[i], awk::typeof(__arr[i])))
	    testing::assert_equal(force_arr["newval_type"], "unassigned",
				  1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	    @dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			    force_arr["val"], force_arr["newval"], force_arr["newval_type"]))
	    testing::assert_false(awkpot::force_type(__arr[i], "untyped", force_arr),
				  1, sprintf("> ! force_type <%s> (<%s>) to untyped", __arr[i], awk::typeof(__arr[i])))
	    testing::assert_equal(force_arr["newval_type"], "unassigned",
				  1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	    @dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			    force_arr["val"], force_arr["newval"], force_arr["newval_type"]))
	} else {
	    testing::assert_false(awkpot::force_type(__arr[i], "unassigned", force_arr),
				  1, sprintf("> ! force_type <%s> (<%s>) to unassigned", __arr[i], awk::typeof(__arr[i])))
	    testing::assert_equal(force_arr["newval_type"], "untyped",
				  1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	    @dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			    force_arr["val"], force_arr["newval"], force_arr["newval_type"]))
	    testing::assert_true(awkpot::force_type(__arr[i], "untyped", force_arr),
				 1, sprintf("> force_type <%s> (<%s>) to untyped <"i">", __arr[i], awk::typeof(__arr[i])))
	    testing::assert_equal(force_arr["newval_type"], "untyped",
				  1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	    @dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			    force_arr["val"], force_arr["newval"], force_arr["newval_type"]))
	}
    }
    # TEST set_make_regex
    if (awkpot::cmp_version(awkpot::get_version(), "5.2.2", "awkpot::lt")) {
	testing::assert_equal(awkpot::get_make_regex(), "awkpot::_make_regex", 1, "> default make_regex is awkpot::_make_regex")
	# then check another time the returned type
	testing::assert_false(awkpot::force_type("foo", "regexp", force_arr),
			      1, sprintf("> ! force_type <%s> (<%s>) to regexp", "foo", awk::typeof("foo")))
	testing::assert_equal(force_arr["newval_type"], "unassigned", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
    }
    if (awkpot::check_load_module("regexmix", 1, ARGV[0])) {
	# ARGV[0] is unrealiable in some version/implementation of awk... used for tests only, seems work in gawk 5.3.0
	awkpot::set_make_regex("regexmix::make")
	testing::assert_equal(awkpot::get_make_regex(), "regexmix::make", 1, "> default make_regex is regexmix::make")
        testing::assert_true(awkpot::force_type("foo", "regexp", force_arr),
	                     1, sprintf("> ! force_type <%s> (<%s>) to regexp", "foo", awk::typeof("foo")))
	testing::assert_equal(force_arr["newval_type"], "regexp", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
    }

    # TEST exec_command
    # NOTE: assumings <which> is an actual system's command
    # NOTE: other tests for exec_command where testing set_end_exit
    testing::assert_true(awkpot::exec_command("which which"), 1, "> exec_command [which]")
    testing::assert_true(awkpot::exec_command("which which", 0), 1, "> exec_command [which, must_exit=0]")
    testing::assert_true(awkpot::exec_command("which which", 1), 1, "> exec_command [which, must_exit=1]")
    testing::assert_false(awkpot::exec_command(), 1, "> ! exec_command [no args]")
    testing::assert_false(awkpot::exec_command("xx_foo__bar__xx"), 1, "> ! exec_command [invalid command]")
    __cmd = "awk -i awkpot.awk \"BEGIN { awkpot::exec_command(\\\"_____x__foo\\\", 1)}\""
    __r = system(__cmd)
    testing::assert_not_equal(__r, 0, 1, "> ! check exit on error")
    
    # TEST check_load_module
    # NOTE: using ARGV[0] to test with different awk versions (and different executable's name, AWKLIBPATH, etc)
    testing::assert_true(awkpot::check_load_module("awkpot.awk", 0, ARGV[0]), 1, "> check_load_module [awkpot]")
    testing::assert_true(awkpot::check_load_module("awkpot.awk", 0, ARGV[0]), 1, "> check_load_module [awkpot, is_ext=0]")
    testing::assert_false(awkpot::check_load_module("awkpot.awk", 1, ARGV[0]), 1, "> ! check_load_module [awkpot, is_ext=1]")
    testing::assert_true(awkpot::check_load_module("sysutils", 1, ARGV[0]) 1, "> check_load_module [sysutils, is_ext=1]")
    testing::assert_false(awkpot::check_load_module("sysutils", 0, ARGV[0]), 1, "> check_load_module [sysutils, is_ext=0]")

    # TEST random
    testing::assert_nothing(1+awkpot::random(), 1, "> random() [assert_nothing]")
    testing::assert_nothing(1+awkpot::random(0,0,0), 1, "> random() [assert_nothing]")
    testing::assert_nothing(1+awkpot::random(1,11,1), 1, "> random() [assert_nothing]")

    awkpot::random(4, 0, 1)
    for (i=0;i<5;i++)
	__r1[i] = awkpot::random()

    awkpot::random(4, 0, 1)
    for (i=0;i<5;i++)
	__r2[i] = awkpot::random()
    for (i=0;i<5;i++)
	testing::assert_equal(__r1[i], __r2[i], 1, "> random() same seed")

    # test upto
    awkpot::random(0, 0, 1)
    for (i=0;i<5;i++)
	testing::assert_true(length(awkpot::random(0, 1000)) < 4, 1, "> random() upto")

    # test randomness
    awkpot::random(0, 0, 1)
    for (_i=1; _i<=5; _i++) {
	delete __rarr
	tot = (10 ^ _i) % 30000
	for (i=0; i<tot; i++)
	    __rarr[awkpot::random()]
	@dprint(sprintf("> randomness on %5d extraction: %3d%%",  tot, (100 * arrlib::array_length(__rarr)) / tot))
    }

    # TEST get_fmt
    for (i=1; i<10e5; i*=10) {
	conv = i "d"
	fmt = awkpot::get_fmt(i, conv)
	str = sprintf(fmt, i)
	testing::assert_equal(length(str), i, 1, sprintf("> get_fmt basic length [%d]", i))
    }
    for (i=1; i<10e5; i*=10) {
	fmt = awkpot::get_fmt(i, "d", 15)
	str = sprintf(fmt, i)
	testing::assert_equal(length(str), 15, 1, sprintf("> get_fmt maxspace [%d]", i))
    }

    i = 9
    fmt = awkpot::get_fmt(i, "d", 15, "<")
    str = sprintf(fmt, i)
    testing::assert_true(str ~ /^[0-9]\s+/, 1, "> get_fmt padding <")

    fmt = awkpot::get_fmt(i, "d", 15, "c")
    str = sprintf(fmt, i)
    testing::assert_true(str ~ /^\s+[0-9]\s+$/, 1, "> get_fmt padding c")

    fmt = awkpot::get_fmt(i, "d", 15, ">")
    str = sprintf(fmt, i)
    testing::assert_true(str ~ /\s+[0-9]$/, 1, "> get_fmt padding >")

    s = "foobar"
    fmt = awkpot::get_fmt(s, "", 2)
    str = sprintf(fmt, s)
    testing::assert_equal(length(str), length(s), 1, "> get_fmt string overload")

    # TEST strrepeat
    s = "spam"
    sep = ":"
    testing::assert_equal(awkpot::strrepeat(s, 0, sep), s, 1, "> strrepeat (count=0)")
    testing::assert_equal(awkpot::strrepeat(s, 1), s, 1, "> strrepeat (count=1)")
    ns = awkpot::strrepeat(s, 2, sep)
    testing::assert_equal(length(s)*2+length(sep), length(ns), "> strrepeat (x2 + sep)")

    delete __arr
    awkpot::random(0,0,1)
    split("foo::bar:1:yyyyyyyyy", __arr, ":")
    for (i in __arr) {
	s = __arr[i]
	len = length(s)
	count = awkpot::random(0, 50)
	ns = awkpot::strrepeat(s, count)
	nlen = length(ns)
	if (count < 2)
	    testing::assert_equal(len, nlen, 1, sprintf("> strrepeat <%s> (%d) => (%d)", s, count, nlen))
	else
	    testing::assert_equal(len*count, nlen, 1, sprintf("> strrepeat <%s> (%d) => (%d)", s, count, nlen))
	ns = awkpot::strrepeat(s, count, s)
	nlen = length(ns)
	if (count < 2)
	    testing::assert_equal(len, nlen, 1, sprintf("> strrepeat <%s> (%d) => (%d)", s, count, nlen))
	else
	    testing::assert_equal(len*count+len*(count-1), nlen, 1, sprintf("> strrepeat <%s> (%d) [+ sep] => (%d)", s, count, nlen))
    }

    # TEST join
    delete a
    a[0] = "foo"
    a[1] = "bar"
    a[2] = "baz"
    ps = PROCINFO["sorted_in"]
    testing::assert_equal(awkpot::join(a), "foobarbaz", 1, "> join(a)")
    testing::assert_equal(ps, PROCINFO["sorted_in"], 1, "> join: check sort order reset(1)")
    testing::assert_equal(awkpot::join(a, "|"), "foo|bar|baz", 1, "> join(a, \"|\")")
    ps = PROCINFO["sorted_in"]
    testing::assert_equal(awkpot::join(a, "-", "@ind_num_desc"), "baz-bar-foo",
			  1, "> join(a, \"-\", \"@ind_num_desc\")")
    testing::assert_equal(ps, PROCINFO["sorted_in"], 1, "> join: check sort order reset(2)")

    # TEST join_range
    delete a
    for (i=1; i<10; i++)
	a[i] = i
    ps = PROCINFO["sorted_in"]
    testing::assert_equal(awkpot::join_range(a), "123456789", 1, "> join_range(a)")
    testing::assert_equal(ps, PROCINFO["sorted_in"], 1, "> join: check sort order reset(3)")
    testing::assert_equal(awkpot::join_range(a,-1,-1), "123456789", 1, "> join_range(a, -1, -1)")
    testing::assert_equal(awkpot::join_range(a,0,0), "123456789", 1, "> join_range(a, 0, 0)")
    testing::assert_equal(awkpot::join_range(a,1,9), "123456789", 1, "> join_range(a, 1, 9)")
    testing::assert_equal(awkpot::join_range(a,1,1), "1", 1, "> join_range(a, 1, 1)")
    testing::assert_equal(awkpot::join_range(a,1,2), "12", 1, "> join_range(a, 1, 2)")
    testing::assert_equal(awkpot::join_range(a,3,5), "345", 1, "> join_range(a, 3, 5)")
    testing::assert_equal(awkpot::join_range(a,6,8), "678", 1, "> join_range(a, 6, 8)")
    testing::assert_equal(awkpot::join_range(a,6,9), "6789", 1, "> join_range(a, 6, 9)")
    testing::assert_equal(awkpot::join_range(a,6,21), "6789", 1, "> join_range(a, 6, 21)")
    ps = PROCINFO["sorted_in"]
    testing::assert_equal(awkpot::join_range(a,6,21, "-", "@ind_num_desc"), "4-3-2-1",
			  1, "> join_range(a, \"-\", 6, 21,\"@ind_num_desc\")")
    testing::assert_equal(ps, PROCINFO["sorted_in"], 1, "> join: check sort order reset(4)")

    # TEST make_array_record (also tested in arrlib)
    $1 = 1; $2 = 2; $3 = 3
    n = awkpot::make_array_record(rec_arr)
    testing::assert_equal(n, 3, 1, "> make_array_record [return value]")
    for (i=1; i<=3; i++)
	testing::assert_equal($i, rec_arr[i], 1, sprintf("> make_array_record [element at idx %d]", i))

    # TEST rebuild_record
    _old_fs = FS
    _old_ofs = OFS
    FS = "--"
    OFS = FS # set to the same value for simplicity
    $4 = 4
    testing::assert_equal(awkpot::rebuild_record(), "1--2--3--4", 1, "> rebuild_record()")
    testing::assert_equal(awkpot::rebuild_record(-1,-1), "1--2--3--4", 1, "> rebuild_record(-1,-1)")
    testing::assert_equal(awkpot::rebuild_record(1,2), "1--2", 1, "> rebuild_record(1,2)")
    testing::assert_equal(awkpot::rebuild_record(2,4), "2--3--4", 1, "> rebuild_record(2,4)")
    FS = _old_fs
    OFS = _old_ofs
    
    # TEST cmp_version
    testing::assert_true(awkpot::cmp_version(0, PROCINFO["version"], "awkpot::eq"), 1, "> cmp_version eq")
    testing::assert_true(awkpot::cmp_version("5.2.0", "5.2.0", "awkpot::eq"), 1, "> cmp_version eq (1)")
    testing::assert_false(awkpot::cmp_version("5.2.0", "5.1.0", "awkpot::eq"), 1, "> cmp_version ! eq")
    testing::assert_true(awkpot::cmp_version("5.2.0", "5.1.0", "awkpot::ne"), 1, "> cmp_version ne")
    testing::assert_true(awkpot::cmp_version("5.1.0", "5.1.0", "awkpot::le"), 1, "> cmp_version le")
    testing::assert_true(awkpot::cmp_version("5.1.0", "5.2.0", "awkpot::lt"), 1, "> cmp_version lt")
    testing::assert_true(awkpot::cmp_version("5.1.0", "4.2.0", "awkpot::gt"), 1, "> cmp_version gt")
    testing::assert_true(awkpot::cmp_version("5.1.0", "5.1.0", "awkpot::ge"), 1, "> cmp_version ge")
    testing::assert_true(awkpot::cmp_version("5.1.0", "4.1.0", "awkpot::gt", 1), 1, "> cmp_version gt major")
    testing::assert_true(awkpot::cmp_version("5.1.0", "4.1.0", "awkpot::eq", 0, 1), 1, "> cmp_version eq minor")
    testing::assert_true(awkpot::cmp_version("5.1.0", "4.1.0", "awkpot::eq", 0, 0, 1), 1, "> cmp_version eq patch")
    testing::assert_true(awkpot::cmp_version("4.2.0", "4.1.0", "awkpot::eq", 1, 0, 1), 1, "> cmp_version eq major/patch")
    testing::assert_true(awkpot::cmp_version("5.3.1", "5.3.0", "awkpot::eq", 1, 1, 0), 1, "> cmp_version eq major/minor")
    testing::assert_true(awkpot::cmp_version("5.3.1", "4.3.1", "awkpot::eq", 0, 1, 1), 1, "> cmp_version eq major/minor")

    # TEST make_strnum
    sn = awkpot::make_strnum(1)
    testing::assert_equal(typeof(sn), "strnum", 1, "> strnum 1")
    testing::assert_equal(sn, 1, 1, "> sn == 1")
    sn = awkpot::make_strnum(0.27)
    testing::assert_equal(typeof(sn), "strnum", 1, "> strnum 0.27")
    testing::assert_equal(sn, 0.27, 1, "> sn == 0.27")
    sn = awkpot::make_strnum("11")
    testing::assert_equal(typeof(sn), "strnum", 1, "> strnum \"11\"")
    testing::assert_equal(sn, 11, 1, "> sn == 11")
    sn = awkpot::make_strnum(@/12/)
    testing::assert_equal(typeof(sn), "strnum", 1, "> strnum @/12/")
    testing::assert_equal(sn, 12, 1, "> sn == 12")
    sn = awkpot::make_strnum(@//)
    testing::assert_equal(typeof(sn), "strnum", 1, "> strnum @//")
    testing::assert_equal(sn, 0, 1, "> sn == 0")
    sn = awkpot::make_strnum("3.4")
    testing::assert_equal(typeof(sn), "strnum", 1, "> strnum \"3.4\"")
    testing::assert_equal(sn, 3.4, 1, "> sn == 3.4")
    sn = awkpot::make_strnum(-2)
    testing::assert_equal(typeof(sn), "strnum", 1, "> strnum -2")
    testing::assert_equal(sn, -2, 1, "> sn == -2")
    sn = awkpot::make_strnum("-2")
    testing::assert_equal(typeof(sn), "strnum", 0, "> strnum \"-2\"")
    testing::assert_equal(sn, -2, 1, "> sn == -2")
    sn = awkpot::make_strnum("+27.55")
    testing::assert_equal(typeof(sn), "strnum", 1, "> strnum \"+27.55\"")
    testing::assert_equal(sn, 27.55, 1, "> sn == 27.55")    
    sn = awkpot::make_strnum("")
    testing::assert_equal(typeof(sn), "strnum", 1, "> strnum \"\"")
    testing::assert_equal(sn, 0, 1, "> sn == 27.55")

    # TEST make_regex
    if (awkpot::cmp_version(awkpot::get_version(), "5.2.2", "awkpot::ge")) {
	s = "foo"
	r = awkpot::make_regex(s)
	testing::assert_equal(typeof(r), "regexp", 1, sprintf("> make_regex [%s] => regex [%s|%s]", s, r, typeof(r)))
	testing::assert_equal(s, r, 1, sprintf("> make_regex [%s] == [%s]", s, r))
	s = 1
	r = awkpot::make_regex(s)
	testing::assert_equal(typeof(r), "regexp", 1, sprintf("> make_regex [%s] => regex [%s|%s]", s, r, typeof(r)))
	testing::assert_equal("" s, r, 1, sprintf("> make_regex [%s] == (str) [%s]", s, r))
	s = @/^x?y$/
	r = awkpot::make_regex(s)
	testing::assert_equal(typeof(r), "regexp", 1, sprintf("> make_regex [%s] => regex [%s|%s]", s, r, typeof(r)))
	testing::assert_equal(s, r, 1, sprintf("> make_regex [%s] == [%s]", s, r))
	s = @//
	r = awkpot::make_regex(s)
	testing::assert_equal(typeof(r), "regexp", 1, sprintf("> make_regex [%s] => regex [%s|%s]", s, r, typeof(r)))
	testing::assert_equal(s, r, 1, sprintf("> make_regex [%s] == [%s]", s, r))
	s = ""
	r = awkpot::make_regex(s)
	testing::assert_equal(typeof(r), "regexp", 1, sprintf("> make_regex [%s] => regex [%s|%s]", s, r, typeof(r)))
	testing::assert_equal(s, r, 1, sprintf("> make_regex [%s] == [%s]", s, r))
    } else {
	# set to the default _make_regex() function
	awkpot::set_make_regex("awkpot::_make_regex")
	s = "foo"
	r = awkpot::make_regex(s)
	testing::assert_not_equal(r, s, 1, sprintf("> make_regex [%s] =>  [%s|%s]", s, r, typeof(r)))
	# in older gawk version the return's type is string, not regex
	testing::assert_equal(typeof(r), "unassigned", 1, sprintf("[in not recent gawk  version] typeof(%s) == unassigned", s))
	s = 1
	r = awkpot::make_regex(s)
	testing::assert_not_equal(r, "" s, 1, sprintf("> make_regex [%s] =>  (str) [%s|%s]", s, r, typeof(r)))
	testing::assert_equal(typeof(r), "unassigned", 1, sprintf("[in not recent gawk  version] typeof(%s) == unassigned", s))
	s = @/^x?y$/
	r = awkpot::make_regex(s)
	testing::assert_not_equal(r, s, 1, sprintf("> make_regex [%s] => [%s|%s]", s, r, typeof(r)))
	testing::assert_equal(typeof(r), "unassigned", 1, sprintf("[in not recent gawk  version] typeof(%s) == unassigned", s))
	s = @//
	r = awkpot::make_regex(s)
	# empty, equals to unassigned
	testing::assert_equal(r, s, 1, sprintf("> make_regex [%s] => [%s|%s]", s, r, typeof(r)))
	testing::assert_equal(typeof(r), "unassigned", 1, sprintf("[in not recent gawk  version] typeof(%s) == unassigned", s))
	s = ""
	r = awkpot::make_regex(s)
	# empty, equals to unassigned
	testing::assert_equal(r, s, 1, sprintf("> make_regex [%s] => [%s|%s]", s, r, typeof(r)))
	testing::assert_equal(typeof(r), "unassigned", 1, sprintf("[in not recent gawk  version] typeof(%s) == unassigned", s))
    }


    # test cmp, eq / ne
    delete arr
    split("1", arr, ":") # arr[1]
    arr[0] = ""; arr[2] = "str"; arr[3] = @/bar/; arr[4] = 2; arr[5]
    split("2", arr_noeq, ":") # arr_noeq[1] 
    arr_noeq[0] = "str"; arr_noeq[2] = ""; arr_noeq[3] = @/baz/; arr_noeq[4] = -2; arr_noeq[5] = "d"
    for (i in arr) {
	# NOTE: there must be a bug in the version 5.2.2, where regex compares always equal...
	if (awkpot::cmp_version(awkpot::get_version(), "5.2.2", "awkpot::eq"))
	    e = 0
	else
	    e = 1
	testing::assert_true(awkpot::eq(arr[i], arr[i]), e, sprintf("> eq (%s) (%s)", arr[i], arr[i]))
	testing::assert_true(awkpot::cmp(arr[i], arr[i]), e, sprintf("> cmp eq (%s) (%s)", arr[i], arr[i]))
	testing::assert_false(awkpot::eq(arr[i], arr_noeq[i]), e, sprintf("> ! eq (%s) (%s) %s", arr[i], arr_noeq[i], arr[i] == arr_noeq[i]))
	testing::assert_false(awkpot::cmp(arr[i], arr_noeq[i]), e, sprintf("> ! cmp eq (%s) (%s)", arr[i], arr_neq[i]))
	testing::assert_false(awkpot::cmp(arr[i], arr_noeq[i]), e, sprintf("> ! cmp eq (%s) (%s)", arr[i], arr_neq[i]))
	testing::assert_true(awkpot::cmp(arr[i], arr_noeq[i], "awkpot::ne"), e, sprintf("> cmp ne (%s) (%s)", arr[i], arr_noeq[i]))
	testing::assert_false(awkpot::cmp(arr[i], arr[i], "awkpot::ne"), e, sprintf("> ! cmp ne (%s) (%s)", arr[i], arr[i]))
	# le / ge
	testing::assert_true(awkpot::le(arr[i], arr[i]), e, sprintf("> le (%s) (%s)", arr[i], arr[i]))
	testing::assert_true(awkpot::ge(arr[i], arr[i]), e, sprintf("> ge (%s) (%s)", arr[i], arr[i]))
	testing::assert_true(awkpot::cmp(arr[i], arr[i], "awkpot::le"), e, sprintf("> cmp le (%s) (%s)", arr[i], arr[i]))
	testing::assert_true(awkpot::cmp(arr[i], arr[i], "awkpot::ge"), e, sprintf("> cmp ge (%s) (%s)", arr[i], arr[i]))
    }
    if (awkpot::cmp_version(awkpot::get_version(), "5.2.2", "awkpot::lt")) {
	testing::assert_true(awkpot::eq(arr[5], thisisuntyped), 1, "> eq untyped unassigned")
	testing::assert_true(awkpot::eq(thisisuntyped, andthistoo), 1, "> eq untyped")
	testing::assert_false(awkpot::cmp(arr[5], thisisuntyped, "awkpot::ne"), 1, "> ! cmp ne untyped unassigned")
	testing::assert_false(awkpot::cmp(thisisuntyped, andthistoo, "awkpot::ne"), 1, "> ! cmp ne untyped")
	# le / ge
	testing::assert_true(awkpot::cmp(arr[5], thisisuntyped, "awkpot::le"), 1, "> cmp le untyped unassigned")
	testing::assert_true(awkpot::cmp(arr[5], thisisuntyped, "awkpot::ge"), 1, "> cmp ge untyped unassigned")
    } else {
	testing::assert_true(awkpot::eq(arr[5], alsothisisuntyped), 1, "> eq untyped")
	testing::assert_true(awkpot::eq(alsothisisuntyped, andagainthistoo), 1, "> eq untyped")
	testing::assert_false(awkpot::cmp(arr[5], alsothisisuntyped, "awkpot::ne"), 1, "> ! cmp ne untyped")
	testing::assert_false(awkpot::cmp(alsothisisuntyped, andagainthistoo, "awkpot::ne"), 1, "> ! cmp ne untyped")
	# le / ge
	testing::assert_true(awkpot::cmp(arr[5], alsothisisuntyped, "awkpot::le"), 1, "> cmp lq untyped")
	testing::assert_true(awkpot::cmp(arr[5], alsothisisuntyped, "awkpot::ge"), 1, "> cmp ge untyped")
    }
    testing::assert_true(awkpot::eq(arr[5], ""), 1, "> eq untyped/unassigned string")
    testing::assert_false(awkpot::cmp(arr[5], "", "awkpot::ne"), 1, "> ! cmp ne untyped/unassigned string")
    # le / ge
    testing::assert_true(awkpot::cmp(arr[5], "", "awkpot::le"), 1, "> le untyped/unassigned string")
    testing::assert_true(awkpot::cmp(arr[5], "", "awkpot::ge"), 1, "> ge untyped/unassigned string")

    # test gt, lt. Others again for cmp, le, ge
    delete arr
    split("foo::1,x:abc:cba", arr, ":")
    for (i in arr) {
	x = arr[i] "x"
	testing::assert_true(awkpot::cmp(arr[i], x, "awkpot::lt"), 1, sprintf("> gt (%s) (%s)", arr[i], x))
	testing::assert_true(awkpot::cmp(arr[i], x, "awkpot::le"), 1, sprintf("> ge (%s) (%s)", arr[i], x))
	testing::assert_true(awkpot::cmp(x, arr[i], "awkpot::gt"), 1, sprintf("> lt (%s) (%s)", x, arr[i]))
	testing::assert_true(awkpot::cmp(x, arr[i], "awkpot::ge"), 1, sprintf("> le (%s) (%s)", x, arr[i]))
    }
    for (i=-10; i<-5; i++) {
	j = i+1
	testing::assert_true(awkpot::cmp(i, j, "awkpot::le"), 1, sprintf("> cmp le (%s) (%s)", i, j))
	testing::assert_true(awkpot::cmp(i, j, "awkpot::lt"), 1, sprintf("> cmp lt (%s) (%s)", i, j))
	testing::assert_false(awkpot::cmp(i, j, "awkpot::ge"), 1, sprintf("> ! cmp le (%s) (%s)", i, j))
	testing::assert_false(awkpot::cmp(i, j, "awkpot::gt"), 1, sprintf("> ! cmp lt (%s) (%s)", i, j))
    }

    # TEST set_end_exit / end_exit

    delete a
    delete aret
    e = 1
    for (i=1;i<30; i+=7) {
	cmd = sprintf("%s -i awkpot 'BEGIN { awkpot::set_end_exit(%d)} END { awkpot::end_exit() }'", ARGV[0], i)
	r = awkpot::exec_command(cmd, 0, aret)
	testing::assert_false(r, e, sprintf("> ! set_end_exit: %d", i))
	# NOTE testing exec_command's status array too:
	testing::assert_equal(aret[0], i, e, sprintf("> set_end_exit: exit status %d == %d", aret[0], i))
    }

    i = 0
    cmd = sprintf("%s -i awkpot 'BEGIN { awkpot::set_end_exit(%d)} END { awkpot::end_exit() }'", ARGV[0], i)
    r = awkpot::exec_command(cmd, 0, aret)
    testing::assert_equal(aret[0], i, e, sprintf("> set_end_exit: exit status %d == %d", aret[0], i))
    testing::assert_equal(r, 1, e, sprintf("> set_end_exit: %d [retcode = %d]", i, r))

    i = 127
    cmd = sprintf("%s -i awkpot 'BEGIN { awkpot::set_end_exit(%d)} END { awkpot::end_exit() }'", ARGV[0], i)
    r = awkpot::exec_command(cmd, 0, aret)
    testing::assert_false(r, e, sprintf("> ! set_end_exit: %d", i))
    testing::assert_equal(aret[0], 1, e, sprintf("> set_end_exit: [%d] exit status %d == 1", i, 1, aret[0]))
    i = 129
    cmd = sprintf("%s -i awkpot 'BEGIN { awkpot::set_end_exit(%d)} END { awkpot::end_exit() }'", ARGV[0], i)
    r = awkpot::exec_command(cmd, 0, aret)
    testing::assert_false(r, e, sprintf("> set_end_exit: %d", i))
    testing::assert_equal(aret[0], 1, e, sprintf("> ! set_end_exit: [%d] exit status %d == 1", i, aret[0]))
    i = -1
    cmd = sprintf("%s -i awkpot 'BEGIN { awkpot::set_end_exit(%d)} END { awkpot::end_exit() }'", ARGV[0], -1)
    r = awkpot::exec_command(cmd, 0, aret)
    testing::assert_false(r, e, sprintf("> ! set_end_exit: %d", i))
    testing::assert_equal(aret[0], 1, e, sprintf("> set_end_exit: [%d] exit status %d == 1", i, aret[0]))




    
    # report
    testing::end_test_report()
    testing::report()

    # run:
    # ~$ awk -v AWKPOT_DEBUG=1 -f awkpot_test.awk
}
