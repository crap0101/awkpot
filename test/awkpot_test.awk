
@include "awkpot"
@include "arrlib"
# https://github.com/crap0101/awk_arrlib
@include "testing"
# https://github.com/crap0101/laundry_basket/blob/master/testing.awk

BEGIN {

    testing::start_test_report()

    # TEST get_tempfile | run_command | read_file_arr
    t = awkpot::get_tempfile()
    testing::assert_true(t, 1, "> get_tempfile()")

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
    t = awkpot::get_tempfile()
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
    cmd = sprintf("awk -i awkpot.awk 'BEGIN {awkpot::set_dprint(\"awkpot::dprint_real\");awkpot::set_sort_order(\"fake\")}' 2>%s", t)
    ret = awkpot::run_command(cmd, 0, args)
    awkpot::read_file_arr(t, arread)
    print "* arread:"; arrlib::array_print(arread)
    testing::assert_not_equal(0, arrlib::array_length(arread), 1, "> set_dprint (real) (length)")
    testing::assert_equal(2, arrlib::array_length(arread), 1, "> set_dprint (real) (length eq)")
    testing::assert_not_equal("", arrlib::sprintf_val(arread), 1, "> set_dprint (real) (sprintf !eq)")
    delete arread
    
    # TEST set_sort_order
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
    testing::assert_true(awkpot::equals(1, 1), 1, "> equals 1 1")
    testing::assert_true(awkpot::equals(1, "1"), 1, "> equals 1 \"1\"")
    testing::assert_false(awkpot::equals(1, "1", 1), 1, "> ! equals 1 \"1\"") # typed
    testing::assert_true(awkpot::equals("foo", "foo"), 1, "> equals \"foo\" \"foo\"")
    testing::assert_false(awkpot::equals(0, ""), 1, "> ! equals 0 \"\"")
    arr1[0] = 1 ; arr1[1] = 1
    arr2[0] = 10 ; arr2[1] = 11
    arr3[11] = 1 ; arr3[10] = 0
    testing::assert_true(awkpot::equals(arr1, arr2), 1, "> equals arr1 arr2")
    testing::assert_true(awkpot::equals(arr3, arr2), 1, "> equals arr3 arr2")
    print "* delete arr1"
    delete arr1
    testing::assert_true(awkpot::equals(arr1, arr3), 1, "> equals arr1 arr3")
    testing::assert_false(awkpot::equals("foo", arr3), 1, "> ! equals \"foo\" arr3")
    testing::assert_false(awkpot::equals("foo", "foo "), 1, "> ! equals \"foo\" \"foo \"")

    # TEST equals_typed
    testing::assert_equal(awkpot::equals(1, 1), awkpot::equals_typed(1, 1), 1, "> equals/typed 1 1")
    testing::assert_not_equal(awkpot::equals(1, "1"), awkpot::equals_typed(1, "1"), 1, "> ! equals/typed 1 \"1\"")
    testing::assert_equal(awkpot::equals(1, "1", 1), awkpot::equals_typed(1, "1"), 1, "> equals+t/typed 1 \"1\"")


# report
    testing::end_test_report()
    testing::report()

    # awk -f thisfile
}
