#!/usr/bin/awk -f

function usage() {
    print "Usage: semver_compare.awk \"<version1> <operator> <version2>\""
    print "  Compares semantic versions with 1 to 3 segments."
    print "  Operators: >, >=, <, <=, ==, !="
    print ""
    print "Examples:"
    print "  ./semver_compare.awk \"1.2 > 1.0\""
    print "  ./semver_compare.awk \"1.2.0 == 1.2\""
    exit 2
}

function parse_version(v, arr,    parts, n, i) {
    n = split(v, parts, /\./)
    for (i = 1; i <= 3; i++) {
        arr[i] = (i <= n) ? parts[i] + 0 : 0
    }
}

function compare_versions(v1, op, v2,    a, b, i, cmp) {
    parse_version(v1, a)
    parse_version(v2, b)

    cmp = 0
    for (i = 1; i <= 3; i++) {
        if (a[i] < b[i]) { cmp = -1; break }
        if (a[i] > b[i]) { cmp = 1; break }
    }

    if ((op == ">"  && cmp ==  1) ||
        (op == "<"  && cmp == -1) ||
        (op == ">=" && cmp >= 0) ||
        (op == "<=" && cmp <= 0) ||
        (op == "==" && cmp ==  0) ||
        (op == "!=" && cmp != 0)) {
        return 0
    } else {
        return 1
    }
}

function trim(str) {
    gsub(/^[ \t]+/, "", str)
    gsub(/[ \t]+$/, "", str)
    return str
}

function parse_expr(expr, v, op, w, tokens, nt) {
    expr = trim(expr)
    nt = split(expr, tokens, /[ \t]+/)
    if (nt != 3) return 1
    v = tokens[1]
    op = tokens[2]
    w = tokens[3]
    return (v != "" && op ~ /^(<|<=|>|>=|==|!=)$/ && w != "")
}

function self_test() {
    print "Running self-tests..."

    test("1 > 0.9", 0)
    test("1.2 == 1.2.0", 0)
    test("1.2.3 < 1.3", 0)
    test("1.2.3 != 1.2.3", 1)
    test("1.2.3 <= 1.2.3", 0)
    test("2 >= 2.0.0", 0)
    test("0.9.9 < 1", 0)

    print "All tests passed."
}

function test(expr, expected,   result, tokens, v1, op, v2) {
    expr = trim(expr)
    n = split(expr, tokens, /[ \t]+/)
    if (n != 3) {
        print "Invalid test expression: " expr
        exit 1
    }
    v1 = tokens[1]
    op = tokens[2]
    v2 = tokens[3]

    result = compare_versions(v1, op, v2)
    if (result != expected) {
        print "FAILED: " expr " (expected " expected ", got " result ")"
        exit 1
    }
}

BEGIN {
    if (ENVIRON["__TEST__"] != "") {
        self_test()
    }

    if (ARGC < 2) {
        usage()
    }

    expr = ARGV[1]
    ARGV[1] = ""

    expr = trim(expr)
    n = split(expr, tokens, /[ \t]+/)
    if (n != 3) {
        print "Invalid semver expression: '" expr "'" > "/dev/stderr"
        exit 2
    }

    v1 = tokens[1]
    op = tokens[2]
    v2 = tokens[3]

    exit compare_versions(v1, op, v2)
}
