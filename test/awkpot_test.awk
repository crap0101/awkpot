
@include "awkpot"
@include "arrlib"
# https://github.com/crap0101/awk_arrlib
@include "testing"
# https://github.com/crap0101/awk_testing

@load "sysutils"
# https://github.com/crap0101/awk_sysutils

# NOTES:
# * Some tests uses system's commands: which, seq, awk          # :D
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
    s_arr = arrlib::sprintf_val(arread, "\n")
    s_arr = s_arr "\n" # append a newline cuz run_command outputs this way
    testing::assert_equal(run["output"], s_arr, 1, "> run_command output == (sprintf_val) arread")
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
    testing::assert_equal("", arrlib::sprintf_val(arread), 1, "> dprint fake (sprintf)")
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
    testing::assert_not_equal("", arrlib::sprintf_val(arread), 1, "> set_dprint (real) (sprintf !eq)")
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
    print awkpot::cmkbool(1)
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
    split("foo::2,3", str_arr, ":")
    str_arr[22]
    split("1:2.3:1e2", strnum_arr, ":")
    strnum_arr[23]
    num_arr[0]=0
    num_arr[1]=11
    num_arr[2]=1e2
    num_arr[3]
    reg_arr[0] = @/^foo/
    reg_arr[1] = @/1/
    @dprint("* test force_type:")
    for (i in str_arr) {
	testing::assert_true(awkpot::force_type(str_arr[i], "string", force_arr),
			     1, sprintf("> force_type <%s> (<%s>) to string", str_arr[i], awk::typeof(str_arr[i])))
	testing::assert_equal(force_arr["newval_type"], "string", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))

	@dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))

	testing::assert_false(awkpot::force_type(str_arr[i], "regexp", force_arr),
			     1, sprintf("> ! force_type <%s> (<%s>) to regexp", str_arr[i], awk::typeof(str_arr[i])))
	@dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))

	testing::assert_true(awkpot::force_type(str_arr[i], "number", force_arr),
			     1, sprintf("> force_type <%s> (<%s>) to number", str_arr[i], awk::typeof(str_arr[i])))
	testing::assert_equal(force_arr["newval_type"], "number", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	@dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))

	testing::assert_true(awkpot::force_type(str_arr[i], "bool", force_arr),
			     1, sprintf("> force_type <%s> (<%s>) to bool", str_arr[i], awk::typeof(str_arr[i])))
	testing::assert_true(force_arr["newval_type"] == "number" || force_arr["newval_type"] == "number|bool",
			     1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	@dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))
    }
    for (i in strnum_arr) {
	testing::assert_true(awkpot::force_type(strnum_arr[i], "string", force_arr),
			     1, sprintf("> force_type <%s> (<%s>) to string", strnum_arr[i], awk::typeof(strnum_arr[i])))
	testing::assert_equal(force_arr["newval_type"], "string", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	@dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))

	testing::assert_false(awkpot::force_type(strnum_arr[i], "regexp", force_arr),
			     1, sprintf("> ! force_type <%s> (<%s>) to regexp", strnum_arr[i], awk::typeof(strnum_arr[i])))
	@dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))

	testing::assert_true(awkpot::force_type(strnum_arr[i], "number", force_arr),
			     1, sprintf("> force_type <%s> (<%s>) to number", strnum_arr[i], awk::typeof(strnum_arr[i])))
	testing::assert_equal(force_arr["newval_type"], "number", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	@dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))

	testing::assert_true(awkpot::force_type(strnum_arr[i], "bool", force_arr),
			     1, sprintf("> force_type <%s> (<%s>) to bool", strnum_arr[i], awk::typeof(strnum_arr[i])))
	testing::assert_true(force_arr["newval_type"] == "number" || force_arr["newval_type"] == "number|bool",
			     1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	@dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))
    }
    for (i in num_arr) {
	testing::assert_true(awkpot::force_type(num_arr[i], "string", force_arr),
			     1, sprintf("> force_type <%s> (<%s>) to string", num_arr[i], awk::typeof(num_arr[i])))
	testing::assert_equal(force_arr["newval_type"], "string", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))

	@dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))

	testing::assert_false(awkpot::force_type(num_arr[i], "regexp", force_arr),
			     1, sprintf("> ! force_type <%s> (<%s>) to regexp", num_arr[i], awk::typeof(num_arr[i])))
	@dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))

	testing::assert_true(awkpot::force_type(num_arr[i], "number", force_arr),
			     1, sprintf("> force_type <%s> (<%s>) to number", num_arr[i], awk::typeof(num_arr[i])))
	testing::assert_equal(force_arr["newval_type"], "number", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	@dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))

	testing::assert_true(awkpot::force_type(num_arr[i], "bool", force_arr),
			     1, sprintf("> force_type <%s> (<%s>) to bool", num_arr[i], awk::typeof(num_arr[i])))
	testing::assert_true(force_arr["newval_type"] == "number" || force_arr["newval_type"] == "number|bool",
			     1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	@dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))
    }
    for (i in reg_arr) {
	testing::assert_true(awkpot::force_type(reg_arr[i], "string", force_arr),
			     1, sprintf("> force_type <%s> (<%s>) to string", reg_arr[i], awk::typeof(reg_arr[i])))
	testing::assert_equal(force_arr["newval_type"], "string", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	@dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))

	testing::assert_true(awkpot::force_type(reg_arr[i], "regexp", force_arr),
			     1, sprintf("> force_type <%s> (<%s>) to regexp", reg_arr[i], awk::typeof(reg_arr[i])))
	testing::assert_equal(force_arr["newval_type"], "regexp", 1, sprintf("> check equals: type newval_type (%s)", force_arr["newval_type"]))
	@dprint(sprintf("* forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))

	testing::assert_false(awkpot::force_type(reg_arr[i], "number", force_arr),
			     1, sprintf("> ! force_type <%s> (<%s>) to number", reg_arr[i], awk::typeof(reg_arr[i])))
	@dprint(sprintf("* (failed) forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))

	testing::assert_false(awkpot::force_type(reg_arr[i], "bool", force_arr),
			     1, sprintf("> ! force_type <%s> (<%s>) to bool", reg_arr[i], awk::typeof(reg_arr[i])))
	@dprint(sprintf("* (failed) forcing <%s> gets <%s> (type: <%s>)",
			force_arr["val"], force_arr["newval"], force_arr["newval_type"]))
    }

    # TEST exec_command
    # NOTE: assumings <which> is an actual system's command
    testing::assert_true(awkpot::exec_command("which which"), 1, "> exec_command [which]")
    testing::assert_true(awkpot::exec_command("which which", 0), 1, "> exec_command [which, must_exit=0]")
    testing::assert_true(awkpot::exec_command("which which", 1), 1, "> exec_command [which, must_exit=1]")
    testing::assert_false(awkpot::exec_command(), 1, "> ! exec_command [no args]")
    testing::assert_false(awkpot::exec_command("xx_foo__bar__xx"), 1, "> ! exec_command [invalid command]")
    __cmd = "awk -i awkpot.awk \"BEGIN { awkpot::exec_command(\\\"_____x__foo\\\", 1)}\""
    __r = system(__cmd)
    testing::assert_not_equal(__r, 0, 1, "> ! check exit on error")
    
    # TEST check_load_module
    testing::assert_true(awkpot::check_load_module("awkpot.awk"), 1, "> check_load_module [awkpot]")
    testing::assert_true(awkpot::check_load_module("awkpot.awk", 0), 1, "> check_load_module [awkpot, is_ext=0]")
    testing::assert_false(awkpot::check_load_module("awkpot.awk", 1), 1, "> ! check_load_module [awkpot, is_ext=1]")
    testing::assert_false(awkpot::check_load_module("sysutils"), 1, "> ! check_load_module [sysutils]")
    testing::assert_true(awkpot::check_load_module("sysutils", 1) 1, "> check_load_module [sysutils, is_ext=1]")
    testing::assert_false(awkpot::check_load_module("sysutils", 0), 1, "> check_load_module [sysutils, is_ext=0]")

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
    
    # report
    testing::end_test_report()
    testing::report()

    # run:
    # ~$ awk -v AWKPOT_DEBUG=1 -f awkpot_test.awk
}
