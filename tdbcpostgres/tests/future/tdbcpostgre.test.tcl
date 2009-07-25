
#this test was abandonded, because no flags are used as for now
test tdbc::postgres-1.4 {create a connection, bad flag} {*}{
    -body {
	tdbc::postgres::connection create db -interactive rubbish
    }
    -returnCodes error
    -result {expected boolean value but got "rubbish"}
}


#Theese two test are delayed, cause only varchar type is implemented as for now
test tdbc::postgres-5.4 {paramtype - bad scale} {*}{
    -setup {
	set stmt [::db prepare {
	    INSERT INTO people(idnum, name, info) values(:idnum, :name, 0)
	}]
    }
    -body {
	$stmt paramtype idnum decimal rubbish
    }
    -cleanup {
	rename $stmt {}
    }
    -returnCodes error
    -match glob
    -result {expected integer but got "rubbish"}
}

test tdbc::postgres-5.5 {paramtype - bad precision} {*}{
    -setup {
	set stmt [::db prepare {
	    INSERT INTO people(idnum, name, info) values(:idnum, :name, 0)
	}]
    }
    -body {
	$stmt paramtype idnum decimal 12 rubbish
    }
    -cleanup {
	rename $stmt {}
    }
    -returnCodes error
    -match glob
    -result {expected integer but got "rubbish"}
}



############### FUTURE tests:

test tdbc::postgres-8.2 {nextrow - as lists} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people ORDER BY idnum
	}]
	set rs [$stmt execute]
    }
    -body {
	set idnum 1
	set names {}
	while {[$rs nextrow -as lists -- row]} {
	    if {$idnum != [lindex $row 0]} {
		error [list bad idnum [lindex $row 0] should be $idnum]
	    }
	    lappend names [lindex $row 1]
	    incr idnum
	}
	set names
    }
    -cleanup {
	rename $rs {}
	rename $stmt {}
    }
    -result {fred wilma pebbles barney betty bam-bam}
}






test tdbc::postgres-8.3 {nextrow - bad cursor state} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people ORDER BY idnum
	}]
    }
    -body {
	set rs [$stmt execute]
	set names {}
	while {[$rs nextrow row]} {}
	$rs nextrow row
    }
    -cleanup {
	rename $rs {}
	rename $stmt {}
    }
    -result 0
}

test tdbc::postgres-8.4 {anonymous columns - dicts} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT COUNT(*), MAX(idnum) FROM people
	}]
	set rs [$stmt execute]
    }
    -body {
	list \
	    [$rs nextrow row] \
	    $row \
	    [$rs nextrow row]
    }
    -cleanup {
	$stmt close
    }
    -match glob
    -result {1 {* 6 * 6} 0}
};

test tdbc::postgres-8.5 {anonymous columns - lists} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT COUNT(*), MAX(idnum) FROM people
	}]
	set rs [$stmt execute]
    }
    -body {
	list [$rs nextrow -as lists row] \
	    $row \
	    [$rs nextrow -as lists row]
    }
    -cleanup {
	$stmt close
    }
    -result {1 {6 6} 0}
};

test tdbc::postgres-8.6 {null results - dicts} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name, info FROM people WHERE name = 'fred'
	}]
	set rs [$stmt execute]
    }
    -body {
	list [$rs nextrow row] $row [$rs nextrow row]
    }
    -cleanup {
	$stmt close
    }
    -result {1 {idnum 1 name fred} 0}
}

test tdbc::postgres-8.7 {null results - lists} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name, info FROM people WHERE name = 'fred'
	}]
	set rs [$stmt execute]
    }
    -body {
	list [$rs nextrow -as lists -- row] $row [$rs nextrow -as lists -- row]
    }
    -cleanup {
	$stmt close
    }
    -result {1 {1 fred {}} 0}
}
	
test tdbc::postgres-9.1 {rs foreach var script} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}]
	set rs [$stmt execute]
    }
    -body {
	set result {}
	$rs foreach row {
	    lappend result $row
	}
	set result
    }
    -cleanup {
	$rs close
	$stmt close
    }
    -result {{idnum 4 name barney} {idnum 5 name betty} {idnum 6 name bam-bam}}
}

test tdbc::postgres-9.2 {stmt foreach var script} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}]

    }
    -body {
	set result {}
	$stmt foreach row {
	    lappend result $row
	}
	set result
    }
    -cleanup {
	$stmt close
    }
    -result {{idnum 4 name barney} {idnum 5 name betty} {idnum 6 name bam-bam}}
}

test tdbc::postgres-9.3 {db foreach var sqlcode script} {*}{
    -body {
	set result {}
	db foreach row {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	} {
	    lappend result $row
	}
	set result
    }
    -result {{idnum 4 name barney} {idnum 5 name betty} {idnum 6 name bam-bam}}
}

test tdbc::postgres-9.4 {rs foreach -- var script} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}]
	set rs [$stmt execute]
    }
    -body {
	set result {}
	$rs foreach -- row {
	    lappend result $row
	}
	set result
    }
    -cleanup {
	$rs close
	$stmt close
    }
    -result {{idnum 4 name barney} {idnum 5 name betty} {idnum 6 name bam-bam}}
}

test tdbc::postgres-9.5 {stmt foreach -- var script} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}]
    }
    -body {
	set result {}
	$stmt foreach -- row {
	    lappend result $row
	}
	set result
    }
    -cleanup {
	$stmt close
    }
    -result {{idnum 4 name barney} {idnum 5 name betty} {idnum 6 name bam-bam}}
}

test tdbc::postgres-9.6 {db foreach -- var query script} {*}{
    -body {
	set result {}
	db foreach -- row {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	} {
	    lappend result $row
	}
	set result
    }
    -result {{idnum 4 name barney} {idnum 5 name betty} {idnum 6 name bam-bam}}
}

test tdbc::postgres-9.7 {rs foreach -- -as lists} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name, info FROM people WHERE name LIKE 'b%'
	}]
	set rs [$stmt execute]
    }
    -body {
	set result {}
	$rs foreach -as lists row {
	    lappend result $row
	}
	set result
    }
    -cleanup {
	$rs close
	$stmt close
    }
    -result {{4 barney {}} {5 betty {}} {6 bam-bam {}}}
}

test tdbc::postgres-9.8 {stmt foreach -as lists} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name, info FROM people WHERE name LIKE 'b%'
	}]
    }
    -body {
	set result {}
	$stmt foreach -as lists row {
	    lappend result $row
	}
	set result
    }
    -cleanup {
	$stmt close
    }
    -result {{4 barney {}} {5 betty {}} {6 bam-bam {}}}
}

test tdbc::postgres-9.9 {db foreach -as lists} {*}{
    -body {
	set result {}
	db foreach -as lists row {
	    SELECT idnum, name, info FROM people WHERE name LIKE 'b%'
	} {
	    lappend result $row
	}
	set result
    }
    -result {{4 barney {}} {5 betty {}} {6 bam-bam {}}}
}

test tdbc::postgres-9.10 {rs foreach -as lists --} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name, info FROM people WHERE name LIKE 'b%'
	}]
	set rs [$stmt execute]
    }
    -body {
	set result {}
	$rs foreach -as lists -- row {
	    lappend result $row
	}
	set result
    }
    -cleanup {
	$rs close
	$stmt close
    }
    -result {{4 barney {}} {5 betty {}} {6 bam-bam {}}}
}

test tdbc::postgres-9.11 {stmt foreach -as lists --} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name, info FROM people WHERE name LIKE 'b%'
	}]
    }
    -body {
	set result {}
	$stmt foreach -as lists -- row {
	    lappend result $row
	}
	set result
    }
    -cleanup {
	$stmt close
    }
    -result {{4 barney {}} {5 betty {}} {6 bam-bam {}}}
}

test tdbc::postgres-9.12 {db foreach -as lists --} {*}{
    -body {
	set result {}
	db foreach -as lists row {
	    SELECT idnum, name, info FROM people WHERE name LIKE 'b%'
	} {
	    lappend result $row
	}
	set result
    }
    -result {{4 barney {}} {5 betty {}} {6 bam-bam {}}}
}

test tdbc::postgres-9.13 {rs foreach -as lists -columnsvar c --} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}]
	set rs [$stmt execute]
    }
    -body {
	set result {}
	$rs foreach -as lists -columnsvar c -- row {
	    foreach cn $c cv $row {
		lappend result $cn $cv
	    }
	}
	set result
    }
    -cleanup {
	$rs close
	$stmt close
    }
    -result {idnum 4 name barney idnum 5 name betty idnum 6 name bam-bam}
}

test tdbc::postgres-9.14 {stmt foreach -as lists -columnsvar c --} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}]
    }
    -body {
	set result {}
	$stmt foreach -as lists -columnsvar c -- row {
	    foreach cn $c cv $row {
		lappend result $cn $cv
	    }
	}
	set result
    }
    -cleanup {
	$stmt close
    }
    -result {idnum 4 name barney idnum 5 name betty idnum 6 name bam-bam}
}

test tdbc::postgres-9.15 {db foreach -as lists -columnsvar c --} {*}{
    -body {
	set result {}
	db foreach -as lists -columnsvar c -- row {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	} {
	    foreach cn $c cv $row {
		lappend result $cn $cv
	    }
	}
	set result
    }
    -result {idnum 4 name barney idnum 5 name betty idnum 6 name bam-bam}
}

test tdbc::postgres-9.16 {rs foreach / break out of loop} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name, info FROM people WHERE name LIKE 'b%'
	}]
	set rs [$stmt execute]
    }
    -body {
	set result {}
	$rs foreach -as lists -- row {
	    if {[lindex $row 1] eq {betty}} break
	    lappend result $row
	}
	set result
    }
    -cleanup {
	$rs close
	$stmt close
    }
    -result {{4 barney {}}}
}

test tdbc::postgres-9.17 {stmt foreach / break out of loop} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name, info FROM people WHERE name LIKE 'b%'
	}]
    }
    -body {
	set result {}
	$stmt foreach -as lists -- row {
	    if {[lindex $row 1] eq {betty}} break
	    lappend result $row
	}
	set result
    }
    -cleanup {
	$stmt close
    }
    -result {{4 barney {}}}
}

test tdbc::postgres-9.18 {db foreach / break out of loop} {*}{
    -body {
	set result {}
	db foreach -as lists -- row {
	    SELECT idnum, name, info FROM people WHERE name LIKE 'b%'
	} {
	    if {[lindex $row 1] eq {betty}} break
	    lappend result $row
	}
	set result
    }
    -result {{4 barney {}}}
}

test tdbc::postgres-9.19 {rs foreach / continue in loop} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name, info FROM people WHERE name LIKE 'b%'
	}]
	set rs [$stmt execute]
    }
    -body {
	set result {}
	$rs foreach -as lists -- row {
	    if {[lindex $row 1] eq {betty}} continue
	    lappend result $row
	}
	set result
    }
    -cleanup {
	$rs close
	$stmt close
    }
    -result {{4 barney {}} {6 bam-bam {}}}
}

test tdbc::postgres-9.20 {stmt foreach / continue in loop} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name, info FROM people WHERE name LIKE 'b%'
	}]
    }
    -body {
	set result {}
	$stmt foreach -as lists -- row {
	    if {[lindex $row 1] eq {betty}} continue
	    lappend result $row
	}
	set result
    }
    -cleanup {
	$stmt close
    }
    -result {{4 barney {}} {6 bam-bam {}}}
}

test tdbc::postgres-9.21 {db foreach / continue in loop} {*}{
    -body {
	set result {}
	db foreach -as lists -- row {
	    SELECT idnum, name, info FROM people WHERE name LIKE 'b%'
	} {
	    if {[lindex $row 1] eq {betty}} continue
	    lappend result $row
	}
	set result
    }
    -result {{4 barney {}} {6 bam-bam {}}}
}

test tdbc::postgres-9.22 {rs foreach / return out of the loop} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}]
	set rs [$stmt execute]
	proc tdbcpostgres-9.22 {rs} {
	    $rs foreach -as lists -- row {
		if {[lindex $row 1] eq {betty}} {
		    return [lindex $row 0]
		}
	    }
	    return failed
	}
    }
    -body {
	tdbcpostgres-9.22 $rs
    }
    -cleanup {
	rename tdbcpostgres-9.22 {}
	rename $rs {}
	rename $stmt {}
    }
    -result 5
}

test tdbc::postgres-9.23 {stmt foreach / return out of the loop} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}]
	proc tdbcpostgres-9.23 {stmt} {
	    $stmt foreach -as lists -- row {
		if {[lindex $row 1] eq {betty}} {
		    return [lindex $row 0]
		}
	    }
	    return failed
	}
    }
    -body {
	tdbcpostgres-9.23 $stmt
    }
    -cleanup {
	rename tdbcpostgres-9.23 {}
	rename $stmt {}
    }
    -result 5
}

test tdbc::postgres-9.24 {db foreach / return out of the loop} {*}{
    -setup {
	proc tdbcpostgres-9.24 {stmt} {
	    db foreach -as lists -- row {
		SELECT idnum, name FROM people WHERE name LIKE 'b%'
	    } {
		if {[lindex $row 1] eq {betty}} {
		    return [lindex $row 0]
		}
	    }
	    return failed
	}
    }
    -body {
	tdbcpostgres-9.24 $stmt
    }
    -cleanup {
	rename tdbcpostgres-9.24 {}
    }
    -result 5
}

test tdbc::postgres-9.25 {rs foreach / error out of the loop} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}]
	set rs [$stmt execute]
	proc tdbcpostgres-9.25 {rs} {
	    $rs foreach -as lists -- row {
		if {[lindex $row 1] eq {betty}} {
		    error [lindex $row 0]
		}
	    }
	    return failed
	}
    }
    -body {
	tdbcpostgres-9.25 $rs
    }
    -cleanup {
	rename tdbcpostgres-9.25 {}
	rename $rs {}
	rename $stmt {}
    }
    -returnCodes error
    -result 5
}

test tdbc::postgres-9.26 {stmt foreach - error out of the loop} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}]
	proc tdbcpostgres-9.26 {stmt} {
	    $stmt foreach -as lists -- row {
		if {[lindex $row 1] eq {betty}} {
		    error [lindex $row 0]
		}
	    }
	    return failed
	}
    }
    -body {
	tdbcpostgres-9.26 $stmt
    }
    -cleanup {
	rename tdbcpostgres-9.26 {}
	rename $stmt {}
    }
    -returnCodes error
    -result 5
}

test tdbc::postgres-9.27 {db foreach / error out of the loop} {*}{
    -setup {
	proc tdbcpostgres-9.27 {} {
	    db foreach -as lists -- row {
		SELECT idnum, name FROM people WHERE name LIKE 'b%'
	    } {
		if {[lindex $row 1] eq {betty}} {
		    error [lindex $row 0]
		}
	    }
	    return failed
	}
    }
    -body {
	tdbcpostgres-9.27
    }
    -cleanup {
	rename tdbcpostgres-9.27 {}
    }
    -returnCodes error
    -result 5
}

test tdbc::postgres-9.28 {rs foreach / unknown status from the loop} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}]
	set rs [$stmt execute]
	proc tdbcpostgres-9.28 {rs} {
	    $rs foreach -as lists -- row {
		if {[lindex $row 1] eq {betty}} {
		    return -code 666 -level 0 [lindex $row 0]
		}
	    }
	    return failed
	}
    }
    -body {
	tdbcpostgres-9.28 $rs
    }
    -cleanup {
	rename tdbcpostgres-9.28 {}
	rename $rs {}
	rename $stmt {}
    }
    -returnCodes 666
    -result 5
}

test tdbc::postgres-9.29 {stmt foreach / unknown status from the loop} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}]
	proc tdbcpostgres-9.29 {stmt} {
	    $stmt foreach -as lists -- row {
		if {[lindex $row 1] eq {betty}} {
		    return -code 666 -level 0 [lindex $row 0]
		}
	    }
	    return failed
	}
    }
    -body {
	tdbcpostgres-9.29 $stmt
    }
    -cleanup {
	rename tdbcpostgres-9.29 {}
	rename $stmt {}
    }
    -returnCodes 666
    -result 5
}

test tdbc::postgres-9.30 {db foreach / unknown status from the loop} {*}{
    -setup {
	proc tdbcpostgres-9.30 {stmt} {
	    db foreach -as lists -- row {
		SELECT idnum, name FROM people WHERE name LIKE 'b%'
	    } {
		if {[lindex $row 1] eq {betty}} {
		    return -code 666 -level 0 [lindex $row 0]
		}
	    }
	    return failed
	}
    }
    -body {
	tdbcpostgres-9.30 $stmt
    }
    -cleanup {
	rename tdbcpostgres-9.30 {}
    }
    -returnCodes 666
    -result 5
}

test tdbc::postgres-9.31 {stmt foreach / params in variables} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE :thePattern
	}]
	$stmt paramtype thePattern varchar 40
    }
    -body {
	set result {}
	set thePattern b%
	$stmt foreach row {
	    lappend result $row
	}
	set result
    }
    -cleanup {
	$stmt close
    }
    -result {{idnum 4 name barney} {idnum 5 name betty} {idnum 6 name bam-bam}}
}

test tdbc::postgres-9.32 {db foreach / params in variables} {*}{
    -body {
	set result {}
	set thePattern b%
	db foreach row {
	    SELECT idnum, name FROM people WHERE name LIKE :thePattern
	} {
	    lappend result $row
	}
	set result
    }
    -result {{idnum 4 name barney} {idnum 5 name betty} {idnum 6 name bam-bam}}
}

test tdbc::postgres-9.33 {stmt foreach / parameters in a dictionary} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE :thePattern
	}]
	$stmt paramtype thePattern varchar 40
    }
    -body {
	set result {}
	$stmt foreach row {thePattern b%} {
	    lappend result $row
	}
	set result
    }
    -cleanup {
	$stmt close
    }
    -result {{idnum 4 name barney} {idnum 5 name betty} {idnum 6 name bam-bam}}
}

test tdbc::postgres-9.34 {db foreach / parameters in a dictionary} {*}{
    -body {
	set result {}
	db foreach row {
	    SELECT idnum, name FROM people WHERE name LIKE :thePattern
	} {thePattern b%} {
	    lappend result $row
	}
	set result
    }
    -result {{idnum 4 name barney} {idnum 5 name betty} {idnum 6 name bam-bam}}
}

test tdbc::postgres-9.35 {stmt foreach - variable not found} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE :thePattern
	}]
	$stmt paramtype thePattern varchar 40
	catch {unset thePattern}
    }
    -body {
	set result {}
	set thePattern(bogosity) {}
	$stmt foreach row {
	    lappend result $row
	}
	set result
    }
    -cleanup {
	unset thePattern
	$stmt close
    }
    -result {}
}

test tdbc::postgres-9.36 {db foreach - variable not found} {*}{
    -setup {
	catch {unset thePattern}
    }
    -body {
	set result {}
	set thePattern(bogosity) {}
	db foreach row {
	    SELECT idnum, name FROM people WHERE name LIKE :thePattern
	} {
	    lappend result $row
	}
	set result
    }
    -cleanup {
	unset thePattern
    }
    -result {}
}

test tdbc::postgres-9.37 {rs foreach - too few args} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people
	}]
	set rs [$stmt execute]
    }
    -body {
	$rs foreach row
    }
    -cleanup {
	$rs close
	$stmt close
    }
    -returnCodes error
    -result {wrong # args*} 
    -match glob
}

test tdbc::postgres-9.38 {stmt foreach - too few args} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people
	}]
    }
    -body {
	$stmt foreach row
    }
    -cleanup {
	$stmt close
    }
    -returnCodes error
    -result {wrong # args*} 
    -match glob
}

test tdbc::postgres-9.39 {db foreach - too few args} {*}{
    -body {
	db foreach row {
	    SELECT idnum, name FROM people
	}
    }
    -returnCodes error
    -result {wrong # args*} 
    -match glob
}

test tdbc::postgres-9.40 {rs foreach - too many args} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people
	}]
	set rs [$stmt execute]
    }
    -body {
	$rs foreach row do something 
    }
    -cleanup {
	$rs close
	$stmt close
    }
    -returnCodes error
    -result {wrong # args*} 
    -match glob
}

test tdbc::postgres-9.41 {stmt foreach - too many args} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people
	}]
    }
    -body {
	$stmt foreach row do something else
    }
    -cleanup {
	$stmt close
    }
    -returnCodes error
    -result {wrong # args*} 
    -match glob
}

test tdbc::postgres-9.42 {db foreach - too many args} {*}{
    -body {
	db foreach row {
	    SELECT idnum, name FROM people
	} {} do something
    }
    -returnCodes error
    -result {wrong # args*} 
    -match glob
}

test tdbc::postgres-10.1 {allrows - no args} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}]
	set rs [$stmt execute]
    }
    -body {
	$rs allrows
    }
    -cleanup {
	rename $rs {}
	rename $stmt {}
    }
    -result {{idnum 4 name barney} {idnum 5 name betty} {idnum 6 name bam-bam}}
}

test tdbc::postgres-10.2 {allrows - no args} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}]
    }
    -body {
	$stmt allrows
    }
    -cleanup {
	rename $stmt {}
    }
    -result {{idnum 4 name barney} {idnum 5 name betty} {idnum 6 name bam-bam}}
}

test tdbc::postgres-10.3 {allrows - no args} {*}{
    -body {
	db allrows {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}
    }
    -result {{idnum 4 name barney} {idnum 5 name betty} {idnum 6 name bam-bam}}
}

test tdbc::postgres-10.4 {allrows --} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}]
	set rs [$stmt execute]
    }
    -body {
	$rs allrows --
    }
    -cleanup {
	rename $rs {}
	rename $stmt {}
    }
    -result {{idnum 4 name barney} {idnum 5 name betty} {idnum 6 name bam-bam}}
}

test tdbc::postgres-10.5 {allrows --} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}]
    }
    -body {
	$stmt allrows --
    }
    -cleanup {
	rename $stmt {}
    }
    -result {{idnum 4 name barney} {idnum 5 name betty} {idnum 6 name bam-bam}}
}

test tdbc::postgres-10.6 {allrows --} {*}{
    -body {
	db allrows -- {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}
    }
    -result {{idnum 4 name barney} {idnum 5 name betty} {idnum 6 name bam-bam}}
}    

test tdbc::postgres-10.7 {allrows -as lists} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}]
	set rs [$stmt execute]
    }
    -body {
	$rs allrows -as lists
    }
    -cleanup {
	rename $rs {}
	rename $stmt {}
    }
    -result {{4 barney} {5 betty} {6 bam-bam}}
}

test tdbc::postgres-10.8 {allrows -as lists} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}]
    }
    -body {
	$stmt allrows -as lists
    }
    -cleanup {
	rename $stmt {}
    }
    -result {{4 barney} {5 betty} {6 bam-bam}}
}

test tdbc::postgres-10.9 {allrows -as lists} {*}{
    -body {
	db allrows -as lists {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}
    }
    -result {{4 barney} {5 betty} {6 bam-bam}}
}
    
test tdbc::postgres-10.10 {allrows -as lists --} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}]
	set rs [$stmt execute]
    }
    -body {
	$rs allrows -as lists --
    }
    -cleanup {
	rename $rs {}
	rename $stmt {}
    }
    -result {{4 barney} {5 betty} {6 bam-bam}}
}

test tdbc::postgres-10.11 {allrows -as lists --} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}]
    }
    -body {
	$stmt allrows -as lists --
    }
    -cleanup {
	rename $stmt {}
    }
    -result {{4 barney} {5 betty} {6 bam-bam}}
}

test tdbc::postgres-10.12 {allrows -as lists --} {*}{
    -body {
	db allrows -as lists -- {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}
    }
    -result {{4 barney} {5 betty} {6 bam-bam}}
}

test tdbc::postgres-10.13 {allrows -as lists -columnsvar c} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}]
	set rs [$stmt execute]
    }
    -body {
	set result [$rs allrows -as lists -columnsvar c]
	list $c $result
    }
    -cleanup {
	rename $rs {}
	rename $stmt {}
    }
    -result {{idnum name} {{4 barney} {5 betty} {6 bam-bam}}}
}

test tdbc::postgres-10.14 {allrows -as lists -columnsvar c} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}]
    }
    -body {
	set result [$stmt allrows -as lists -columnsvar c]
	list $c $result
    }
    -cleanup {
	rename $stmt {}
    }
    -result {{idnum name} {{4 barney} {5 betty} {6 bam-bam}}}
}

test tdbc::postgres-10.15 {allrows -as lists -columnsvar c} {*}{
    -body {
	set result [db allrows -as lists -columnsvar c {
	    SELECT idnum, name FROM people WHERE name LIKE 'b%'
	}]
	list $c $result
    }
    -result {{idnum name} {{4 barney} {5 betty} {6 bam-bam}}}
}

test tdbc::postgres-10.16 {allrows - correct lexical scoping of variables} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE :thePattern
	}]
	$stmt paramtype thePattern varchar 40
    }
    -body {
	set thePattern b%
	$stmt allrows
    }
    -cleanup {
	$stmt close
    }
    -result {{idnum 4 name barney} {idnum 5 name betty} {idnum 6 name bam-bam}}
}

test tdbc::postgres-10.17 {allrows - parameters in a dictionary} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people WHERE name LIKE :thePattern
	}]
	$stmt paramtype thePattern varchar 40
    }
    -body {
	$stmt allrows {thePattern b%}
    }
    -cleanup {
	$stmt close
    }
    -result {{idnum 4 name barney} {idnum 5 name betty} {idnum 6 name bam-bam}}
}

test tdbc::postgres-10.18 {allrows - parameters in a dictionary} {*}{
    -body {
	db allrows {
	    SELECT idnum, name FROM people WHERE name LIKE :thePattern
	} {thePattern b%}
    }
    -result {{idnum 4 name barney} {idnum 5 name betty} {idnum 6 name bam-bam}}
}

test tdbc::postgres-10.19 {allrows - variable not found} {*}{
    -setup {
	catch {unset thePattern}
    }
    -body {
	set thePattern(bogosity) {}
	db allrows {
	    SELECT idnum, name FROM people WHERE name LIKE :thePattern
	}
    }
    -cleanup {
	unset thePattern
    }
    -result {}
}

test tdbc::postgres-10.20 {allrows - too many args} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT idnum, name FROM people
	}]
    }
    -body {
	$stmt allrows {} rubbish
    }
    -cleanup {
	$stmt close
    }
    -returnCodes error
    -result {wrong # args*} 
    -match glob
}

test tdbc::postgres-10.21 {bad -as} {*}{
    -body {
	db allrows -as trash {
	    SELECT idnum, name FROM people
	}
    }
    -returnCodes error
    -result {bad variable type "trash": must be lists or dicts}
}

test tdbc::postgres-11.1 {update - no rows} {*}{
    -setup {
	set stmt [::db prepare {
	    UPDATE people SET info = 1 WHERE idnum > 6
	}]
	set rs [$stmt execute]
    }
    -body {
	$rs rowcount
    }
    -cleanup {
	rename $rs {}
	rename $stmt {}
    }
    -result 0
}

test tdbc::postgres-11.2 {update - unique row} {*}{
    -setup {
	set stmt [::db prepare {
	    UPDATE people SET info = 1 WHERE name = 'fred'
	}]
    }
    -body {
	set rs [$stmt execute]
	$rs rowcount
    }
    -cleanup {
	rename $rs {}
	rename $stmt {}
    }
    -result 1
}

test tdbc::postgres-11.3 {update - multiple rows} {*}{
    -setup {
	set stmt [::db prepare {
	    UPDATE people SET info = 1 WHERE name LIKE 'b%'
	}]
    }
    -body {
	set rs [$stmt execute]
	$rs rowcount
    }
    -cleanup {
	rename $rs {}
	rename $stmt {}
    }
    -result 3
}

test tdbc::postgres-12.1 {delete - no rows} {*}{
    -setup {
	set stmt [::db prepare {
	    DELETE FROM people WHERE name = 'nobody'
	}]
    }
    -body {
	set rs [$stmt execute]
	$rs rowcount
    }
    -cleanup {
	rename $rs {}
	rename $stmt {}
    }
    -result 0
}

test tdbc::postgres-12.2 {delete - unique row} {*}{
    -setup {
	set stmt [::db prepare {
	    DELETE FROM people WHERE name = 'fred'
	}]
    }
    -body {
	set rs [$stmt execute]
	$rs rowcount
    }
    -cleanup {
	rename $rs {}
	rename $stmt {}
    }
    -result 1
}

test tdbc::postgres-12.3 {delete - multiple rows} {*}{
    -setup {
	set stmt [::db prepare {
	    DELETE FROM people WHERE name LIKE 'b%'
	}]
    }
    -body {
	set rs [$stmt execute]
	$rs rowcount
    }
    -cleanup {
	rename $rs {}
	rename $stmt {}
    }
    -result 3
}

test tdbc::postgres-13.1 {resultsets - no results} {*}{
    -setup {
	set stmt [::db prepare {
	    SELECT name FROM people WHERE idnum = $idnum
	}]
    }
    -body {
	list \
	    [llength [$stmt resultsets]] \
	    [llength [::db resultsets]]
    }
    -cleanup {
	rename $stmt {}
    }
    -result {0 0}
}

test tdbc::postgres-13.2 {resultsets - various statements and results} {*}{
    -setup {
	for {set i 0} {$i < 6} {incr i} {
	    set stmts($i) [::db prepare {
		SELECT name FROM people WHERE idnum = :idnum
	    }]
	    $stmts($i) paramtype idnum integer
	    for {set j 0} {$j < $i} {incr j} {
		set resultsets($i,$j) [$stmts($i) execute [list idnum $j]]
	    }
	    for {set j 1} {$j < $i} {incr j 2} {
		$resultsets($i,$j) close
		unset resultsets($i,$j)
	    }
	}
    }
    -body {
	set x [list [llength [::db resultsets]]]
	for {set i 0} {$i < 6} {incr i} {
	    lappend x [llength [$stmts($i) resultsets]]
	}
	set x
    }
    -cleanup {
	for {set i 0} {$i < 6} {incr i} {
	    $stmts($i) close
	}
    }
    -result {9 0 1 1 2 2 3}
}

#-------------------------------------------------------------------------------
#
# next tests require a fresh database connection.  Close the existing one down

catch {
    set stmt [db prepare {
	DELETE FROM people
    }]
    $stmt execute
}
catch {
    rename ::db {}
}

tdbc::postgres::connection create ::db {*}$::connFlags
catch {
    set stmt [db prepare {
	INSERT INTO people(idnum, name, info) VALUES(:idnum, :name, NULL)
    }]
    $stmt paramtype idnum integer
    $stmt paramtype name varchar 40
    set idnum 1
    foreach name {fred wilma pebbles barney betty bam-bam} {
	set rs [$stmt execute]
	rename $rs {}
	incr idnum
    }
    rename $stmt {}
}

test tdbc::postgres-14.1 {begin transaction - wrong # args} {*}{
    -body {
	::db begintransaction junk
    }
    -returnCodes error
    -match glob
    -result {wrong # args*}
}

test tdbc::postgres-14.2 {commit - wrong # args} {*}{
    -body {
	::db commit junk
    }
    -returnCodes error
    -match glob
    -result {wrong # args*}
}

test tdbc::postgres-14.3 {rollback - wrong # args} {*}{
    -body {
	::db rollback junk
    }
    -returnCodes error
    -match glob
    -result {wrong # args*}
}

test tdbc::postgres-14.4 {commit - not in transaction} {*}{
    -body {
	list [catch {::db commit} result] $result $::errorCode
    }
    -match glob
    -result {1 {no transaction is in progress} {TDBC GENERAL_ERROR HY010 POSTGRES *}}
}

test tdbc::postgres-14.5 {rollback - not in transaction} {*}{
    -body {
	list [catch {::db rollback} result] $result $::errorCode
    }
    -match glob
    -result {1 {no transaction is in progress} {TDBC GENERAL_ERROR HY010 POSTGRES *}}
}

test tdbc::postgres-14.6 {empty transaction} {*}{
    -body {
	::db begintransaction
	::db commit
    }
    -result {}
}

test tdbc::postgres-14.7 {empty rolled-back transaction} {*}{
    -body {
	::db begintransaction
	::db rollback
    }
    -result {}
}

test tdbcobdc-14.8 {rollback does not change database} {*}{
    -body {
	::db begintransaction
	set stmt [::db prepare {DELETE FROM people WHERE name = 'fred'}]
	set rs [$stmt execute]
	while {[$rs nextrow trash]} {}
	rename $rs {}
	rename $stmt {}
	::db rollback
	set stmt [::db prepare {SELECT idnum FROM people WHERE name = 'fred'}]
	set id {changes still visible after rollback}
	set rs [$stmt execute]
	while {[$rs nextrow -as lists row]} {
	    set id [lindex $row 0]
	}
	rename $rs {}
	rename $stmt {}
	set id
    }
    -result 1
}
test tdbc::postgres-14.9 {commit does change database} {*}{
    -setup {
	set stmt1 [db prepare {
	    INSERT INTO people(idnum, name, info)
	    VALUES(7, 'mr. gravel', 0)
	}]
	set stmt2 [db prepare {
	    SELECT idnum FROM people WHERE name = 'mr. gravel'
	}]
    }
    -body {
	::db begintransaction
	set rs [$stmt1 execute]
	rename $rs {}
	::db commit
	set rs [$stmt2 execute]
	while {[$rs nextrow -as lists row]} {
	    set id [lindex $row 0]
	}
	rename $rs {}
	set id
    }
    -cleanup {
	rename $stmt1 {}
	rename $stmt2 {}
    }
    -result 7
}

test tdbc::postgres-14.10 {nested transactions} {*}{
    -body {
	::db begintransaction
	list [catch {::db begintransaction} result] $result $::errorCode
    }
    -cleanup {
	catch {::db rollback}
    }
    -match glob
    -result {1 {MySQL does not support nested transactions} {TDBC GENERAL_ERROR HYC00 POSTGRES *}}
}

#------------------------------------------------------------------------------
#
# Clean up database again for the next round.

catch {
    set stmt [db prepare {
	DELETE FROM people
    }]
    $stmt execute
}
catch {
    rename ::db {}
}

tdbc::postgres::connection create ::db {*}$::connFlags
catch {
    set stmt [db prepare {
	INSERT INTO people(idnum, name, info) VALUES(:idnum, :name, NULL)
    }]
    $stmt paramtype idnum integer
    $stmt paramtype name varchar 40
    set idnum 1
    foreach name {fred wilma pebbles barney betty bam-bam} {
	set rs [$stmt execute]
	rename $rs {}
	incr idnum
    }
    rename $stmt {}
}

test tdbc::postgres-15.1 {successful (empty) transaction} {*}{
    -body {
	db transaction {
	    concat ok
	}
    }
    -result ok
}

test tdbc::postgres-15.2 {failing transaction does not get committed} {*}{
    -setup {
	set stmt1 [db prepare {
	    DELETE FROM people WHERE name = 'fred'
	}]
	set stmt2 [db prepare {
	    SELECT idnum FROM people WHERE name = 'fred'
	}]
    }
    -body {
	catch {
	    ::db transaction {
		set rs [$stmt1 execute]
		rename $rs {}
		error "abort the transaction"
	    }
	} result
	set id {failed transaction got committed}
	set rs [$stmt2 execute]
	while {[$rs nextrow -as lists row]} {
	    set id [lindex $row 0]
	}
	rename $rs {}
	list $result $id
    }
    -cleanup {
	rename $stmt1 {}
	rename $stmt2 {}
    }
    -result {{abort the transaction} 1}
}

test tdbc::postgres-15.3 {successful transaction gets committed} {*}{
    -setup {
	set stmt1 [db prepare {
	    INSERT INTO people(idnum, name, info)
	    VALUES(7, 'mr. gravel', 0)
	}]
	set stmt2 [db prepare {
	    SELECT idnum FROM people WHERE name = 'mr. gravel'
	}]
    }
    -body {
	::db transaction {
	    set rs [$stmt1 execute]
	    rename $rs {}
	}
	set rs [$stmt2 execute]
	while {[$rs nextrow -as lists row]} {
	    set id [lindex $row 0]
	}
	rename $rs {}
	set id
    }
    -cleanup {
	rename $stmt1 {}
	rename $stmt2 {}
    }
    -result 7
}

test tdbc::postgres-15.4 {break out of transaction commits it} {*}{
    -setup {
	set stmt1 [db prepare {
	    INSERT INTO people(idnum, name, info)
	    VALUES(8, 'gary granite', 0)
	}]
	set stmt2 [db prepare {
	    SELECT idnum FROM people WHERE name = 'gary granite'
	}]
    }
    -body {
	while {1} {
	    ::db transaction {
		set rs [$stmt1 execute]
		rename $rs {}
		break
	    }
	}
	set rs [$stmt2 execute]
	while {[$rs nextrow -as lists row]} {
	    set id [lindex $row 0]
	}
	rename $rs {}
	set id
    }
    -cleanup {
	rename $stmt1 {}
	rename $stmt2 {}
    }
    -result 8
}

test tdbc::postgres-15.5 {continue in transaction commits it} {*}{
    -setup {
	set stmt1 [db prepare {
	    INSERT INTO people(idnum, name, info)
	    VALUES(9, 'hud rockstone', 0)
	}]
	set stmt2 [db prepare {
	    SELECT idnum FROM people WHERE name = 'hud rockstone'
	}]
    }
    -body {
	for {set i 0} {$i < 1} {incr i} {
	    ::db transaction {
		set rs [$stmt1 execute]
		rename $rs {}
		continue
	    }
	}
	set rs [$stmt2 execute]
	while {[$rs nextrow -as lists row]} {
	    set id [lindex $row 0]
	}
	rename $rs {}
	set id
    }
    -cleanup {
	rename $stmt1 {}
	rename $stmt2 {}
    }
    -result 9
}

test tdbc::postgres-15.6 {return in transaction commits it} {*}{
    -setup {
	set stmt1 [db prepare {
	    INSERT INTO people(idnum, name, info)
	    VALUES(10, 'nelson stoneyfeller', 0)
	}]
	set stmt2 [db prepare {
	    SELECT idnum FROM people WHERE name = 'nelson stoneyfeller'
	}]
	proc tdbcpostgres-15.6 {stmt1} {
	    ::db transaction {
		set rs [$stmt1 execute]
		rename $rs {}
		return
	    }
	}
    }
    -body {
	tdbcpostgres-15.6 $stmt1
	set rs [$stmt2 execute]
	while {[$rs nextrow -as lists row]} {
	    set id [lindex $row 0]
	}
	rename $rs {}
	set id
    }
    -cleanup {
	rename $stmt1 {}
	rename $stmt2 {}
	rename tdbcpostgres-15.6 {}
    }
    -result 10
}

test tdbc::postgres-16.1 {database tables, wrong # args} {
    -body {
	set dict [::db tables % rubbish]
    }
    -returnCodes error
    -match glob
    -result {wrong # args*}
}

test tdbc::postgres-16.2 {database tables - empty set} {
    -body {
	::db tables q%
    }
    -result {}
}

test tdbc::postgres-16.3 {enumerate database tables} {*}{
    -body {
	set dict [::db tables]
	list [dict exists $dict people] [dict exists $dict property]
    } 
    -result {1 0}
}

test tdbc::postgres-16.4 {enumerate database tables} {*}{
    -body {
	set dict [::db tables p%]
	list [dict exists $dict people] [dict exists $dict property]
    } 
    -result {1 0}
}

test tdbc::postgres-17.1 {database columns - wrong # args} {*}{
    -body {
	set dict [::db columns people % rubbish]
    }
    -returnCodes error
    -match glob
    -result {wrong # args*}
}

test tdbc::postgres-17.2 {database columns - no such table} {*}{
    -body {
	::db columns rubbish
    }
    -returnCodes error
    -match glob
    -result {Table * doesn't exist}
}

test tdbc::postgres-17.3 {database columns - no match pattern} {*}{
    -body {
	set result {}
	dict for {colname attrs} [::db columns people] {
	    lappend result $colname \
		[dict get $attrs type] \
		[expr {[dict exists $attrs precision] ?
		       [dict get $attrs precision] : {NULL}}] \
		[expr {[dict exists $attrs scale] ?
		       [dict get $attrs scale] : {NULL}}] \
		[dict get $attrs nullable]
	}
	set result
    }
    -match glob
    -result {idnum integer * 0 0 name varchar 40 * info integer * 0 1}
}

# sqlite driver appears not to implement pattern matching for SQLGetColumns
test tdbc::postgres-17.4 {database columns - match pattern} {*}{
    -constraints !sqlite
    -body {
	set result {}
	dict for {colname attrs} [::db columns people i%] {
	    lappend result $colname \
		[dict get $attrs type] \
		[expr {[dict exists $attrs precision] ?
		       [dict get $attrs precision] : {NULL}}] \
		[expr {[dict exists $attrs scale] ?
		       [dict get $attrs scale] : {NULL}}] \
		[dict get $attrs nullable]
	}
	set result
    }
    -result {idnum integer 11 0 0 info integer 11 0 1}
}

test tdbc::postgres-18.1 {$statement params - excess arg} {*}{
    -setup {
	set s [::db prepare {
	    SELECT name FROM people 
	    WHERE name LIKE :pattern
	    AND idnum >= :minid
	}]
	$s paramtype minid numeric 10 0
	$s paramtype pattern varchar 40
    }
    -body {
	$s params excess
    } 
    -cleanup {
	rename $s {}
    }
    -returnCodes error
    -match glob
    -result {wrong # args*}
}

test tdbc::postgres-18.2 {$statement params - no params} {*}{
    -setup {
	set s [::db prepare {
	    SELECT name FROM people 
	}]
    }
    -body {
	$s params
    } 
    -cleanup {
	rename $s {}
    }
    -result {}
}

test tdbc::postgres-18.3 {$statement params - try a few data types} {*}{
    -setup {
	set s [::db prepare {
	    SELECT name FROM people 
	    WHERE name LIKE :pattern
	    AND idnum >= :minid
	}]
	$s paramtype minid decimal 10 0
	$s paramtype pattern varchar 40
    }
    -body {
	set d [$s params]
	list \
	    [dict get $d minid direction] \
	    [dict get $d minid type] \
	    [dict get $d minid precision] \
	    [dict get $d minid scale] \
	    [dict get $d pattern direction] \
	    [dict get $d pattern type] \
	    [dict get $d pattern precision]
    } 
    -cleanup {
	rename $s {}
    }
    -result {in decimal 10 0 in varchar 40}
}

test tdbc::postgres-19.1 {$connection configure - no args} \
    -body {
	::db configure
    } \
    -match glob \
    -result [list \
		 -compress * -database * -encoding utf-8 \
		 -host * -interactive * -isolation repeatableread \
		 -password {} -port * -readonly 0 -socket * \
		 -ssl_ca * -ssl_capath * -ssl_cert * -ssl_cipher * \
		 -ssl_key * -timeout * -user *]

test tdbc::postgres-19.2 {$connection configure - unknown arg} {*}{
    -body {
	::db configure -junk
    }
    -returnCodes error
    -match glob
    -result "bad option *"
}

test tdbc::postgres-19.3 {$connection configure - unknown arg} {*}{
    -body {
	list [catch {::db configure -rubbish} result] $result $::errorCode
    }
    -match glob
    -result {1 {bad option "-rubbish": must be *} {TCL LOOKUP INDEX option -rubbish}}
}

test tdbc::postgres-19.4 {$connection configure - set unknown arg} {*}{
    -body {
	list [catch {::db configure -rubbish rubbish} result] \
	    $result $::errorCode
    }
    -match glob
    -result {1 {bad option "-rubbish": must be *} {TCL LOOKUP INDEX option -rubbish}}
}

test tdbc::postgres-19.5 {$connection configure - set inappropriate arg} {*}{
    -body {
	list [catch {::db configure -encoding ebcdic} result] \
	    $result $::errorCode
    }
    -result {1 {"-encoding" option cannot be changed dynamically} {TDBC GENERAL_ERROR HY000 POSTGRES -1}}
}

test tdbc::postgres-19.6 {$connection configure - wrong # args} {*}{
    -body {
	::db configure -parent . -junk
    }
    -returnCodes error
    -match glob
    -result "wrong # args*"
}

test tdbc::postgres-19.9 {$connection configure - -encoding} {*}{
    -body {
	::db configure -encoding
    }
    -result utf-8
}


test tdbc::postgres-19.10 {$connection configure - -isolation} {*}{
    -body {
	::db configure -isolation junk
    }
    -returnCodes error
    -match glob
    -result {bad isolation level "junk"*}
}

test tdbc::postgres-19.11 {$connection configure - -isolation} {*}{
    -body {
	list [::db configure -isolation readuncommitted] \
	    [::db configure -isolation] \
	    [::db configure -isolation readcommitted] \
	    [::db configure -isolation] \
	    [::db configure -isolation serializable] \
	    [::db configure -isolation] \
	    [::db configure -isolation repeatableread] \
	    [::db configure -isolation]
    }
    -result {{} readuncommitted {} readcommitted {} serializable {} repeatableread}
}

test tdbc::postgres-19.12 {$connection configure - -readonly} {*}{
    -body {
	::db configure -readonly junk
    }
    -returnCodes error
    -result {"-readonly" option cannot be changed dynamically}
}

test tdbc::postgres-19.13 {$connection configure - -readonly} {*}{
    -body {
	::db configure -readonly
    }
    -result 0
}

test tdbc::postgres-19.14 {$connection configure - -timeout} {*}{
    -body {
	::db configure -timeout junk
    }
    -returnCodes error
    -result {expected integer but got "junk"}
}

test tdbc::postgres-19.15 {$connection configure - -timeout} {*}{
    -body {
	set x [::db configure -timeout]
	list [::db configure -timeout 5000] [::db configure -timeout] \
	    [::db configure -timeout $x]
    }
    -result {{} 5000 {}}
}

test tdbc::postgres-19.16 {$connection configure - -db} {*}{
    -body {
	set x [::db configure -db]
	list [::db configure -db information_schema] \
	    [::db configure -db] \
	    [::db configure -db $x]
    }
    -result {{} information_schema {}}
}

test tdbc::postgres-19.17 {$connection configure - -user} \
    -body {
	set flags $::connFlags
	dict unset flags -host
	catch [dict unset flags -port]
	catch [dict unset flags -socket]
	set flags2 $flags
	dict set flags -db information_schema
	list [::db configure {*}$flags] [::db configure -db] \
	    [::db configure {*}$flags2] [::db configure -db]
    } \
    -result [list {} information_schema {} [dict get $connFlags -db]]

test tdbc::postgres-20.1 {bit values} {*}{
    -setup {
	catch {db allrows {DROP TABLE bittest}}
	db allrows {
	    CREATE TABLE bittest (
		bitstring BIT(14)
	    )
	}
	db allrows {INSERT INTO bittest(bitstring) VALUES(b'11010001010110')}
    }
    -body {
	db allrows {SELECT bitstring FROM bittest}
    }
    -result {{bitstring 13398}}
    -cleanup {
	db allrows {DROP TABLE bittest}
    }
}

test tdbc::postgres-20.2 {direct value transfers} {*}{
    -setup {
	set bigtext [string repeat a 200]
	set bigbinary [string repeat \xc2\xa1 100]
	catch {db allrows {DROP TABLE typetest}}
	db allrows {
	    CREATE TABLE typetest (
		xtiny1 TINYINT,
		xsmall1 SMALLINT,
		xint1 INTEGER,
		xfloat1 FLOAT,
		xdouble1 DOUBLE,
		xtimestamp1 TIMESTAMP,
		xbig1 BIGINT,
		xmed1 MEDIUMINT,
		xdate1 DATE,
		xtime1 TIME,
		xdatetime1 DATETIME,
		xyear1 YEAR,
		xbit1 BIT(14),
		xdec1 DECIMAL(10),
		xtinyt1 TINYTEXT,
		xtinyb1 TINYBLOB,
		xmedt1 MEDIUMTEXT,
		xmedb1 MEDIUMBLOB,
		xlongt1 LONGTEXT,
		xlongb1 LONGBLOB,
		xtext1 TEXT,
		xblob1 BLOB,
		xvarb1 VARBINARY(256),
		xvarc1 VARCHAR(256),
		xbin1 BINARY(20),
		xchar1 CHAR(20)
	    )
	}
	set stmt [db prepare {
	    INSERT INTO typetest(
		xtiny1,		xsmall1,	xint1,		xfloat1,
		xdouble1,	xtimestamp1,	xbig1,		xmed1,
		xdate1,		xtime1,		xdatetime1,	xyear1,
		xbit1,		xdec1,		xtinyt1,	xtinyb1,
		xmedt1,		xmedb1,		xlongt1,	xlongb1,
		xtext1,		xblob1,		xvarb1,		xvarc1,
		xbin1,		xchar1
	    ) values (
		:xtiny1,	:xsmall1,	:xint1,		:xfloat1,
		:xdouble1,	:xtimestamp1,	:xbig1,		:xmed1,
		:xdate1,	:xtime1,	:xdatetime1,	:xyear1,
		:xbit1,		:xdec1,		:xtinyt1,	:xtinyb1,
		:xmedt1,	:xmedb1,	:xlongt1,	:xlongb1,
		:xtext1,	:xblob1,	:xvarb1,	:xvarc1,
		:xbin1,		:xchar1
	    )
	}]
	$stmt paramtype xtiny1 tinyint
	$stmt paramtype xsmall1 smallint
	$stmt paramtype xint1 integer
	$stmt paramtype xfloat1 float
	$stmt paramtype xdouble1 double
	$stmt paramtype xtimestamp1 timestamp
	$stmt paramtype xbig1 bigint
	$stmt paramtype xmed1 mediumint
	$stmt paramtype xdate1 date
	$stmt paramtype xtime1 time
	$stmt paramtype xdatetime1 datetime
	$stmt paramtype xyear1 year
	$stmt paramtype xbit1 bit 14
	$stmt paramtype xdec1 decimal 10 0
	$stmt paramtype xtinyt1 tinytext
	$stmt paramtype xtinyb1 tinyblob
	$stmt paramtype xmedt1 mediumtext
	$stmt paramtype xmedb1 mediumblob
	$stmt paramtype xlongt1 longtext
	$stmt paramtype xlongb1 longblob
	$stmt paramtype xtext1 text
	$stmt paramtype xblob1 blob
	$stmt paramtype xvarb1 varbinary
	$stmt paramtype xvarc1 varchar
	$stmt paramtype xbin1 binary 20
	$stmt paramtype xchar1 char 20
    } 
    -body {
	set trouble {}
	set xtiny1 0x14
	set xsmall1 0x3039
	set xint1 0xbc614e
	set xfloat1 1.125
	set xdouble1 1.125
	set xtimestamp1 {2001-02-03 04:05:06}
	set xbig1 0xbc614e
	set xmed1 0x3039
	set xdate1 2001-02-03
	set xtime1 04:05:06
	set xdatetime1 {2001-02-03 04:05:06}
	set xyear1 2001
	set xbit1 0b11010001010110
	set xdec1 0xbc614e
	set xtinyt1 $bigtext
	set xtinyb1 $bigbinary
	set xmedt1 $bigtext
	set xmedb1 $bigbinary
	set xlongt1 $bigtext
	set xlongb1 $bigbinary
	set xtext1 $bigtext
	set xblob1 $bigbinary
	set xvarb1 $bigbinary
	set xvarc1 $bigtext
	set xbin1 [string repeat \xc2\xa1 10]
	set xchar1 [string repeat a 20]
	$stmt allrows
	db foreach row {select * from typetest} {
	    foreach v {
		xtiny1		xsmall1		xint1		xfloat1
		xdouble1	xtimestamp1	xbig1		xmed1
		xdate1		xtime1		xdatetime1	xyear1
		xbit1		xdec1		xtinyt1		xtinyb1
		xmedt1		xmedb1		xlongt1		xlongb1
		xtext1		xblob1		xvarb1		xvarc1
		xbin1		xchar1
	    } {
		if {![dict exists $row $v]} {
		    append trouble $v " did not appear in result set\n"
		} elseif {[set $v] != [dict get $row $v]} {
		    append trouble [list $v is [dict get $row $v] \
					should be [set $v]] \n
		}
	    }
	}
	set trouble
    }
    -result {}
    -cleanup {
	$stmt close
	db allrows {
	    DROP TABLE typetest
	}
    }
}

test tdbc::postgres-21.2 {transfers of binary data} {*}{
    -setup {
	catch {
	    db allrows {DROP TABLE bintest}
	}
	db allrows {
	    CREATE TABLE bintest (
		xint1 INTEGER PRIMARY KEY,
		xbin VARBINARY(256)
	    )
	}
	set stmt1 [db prepare {
	    INSERT INTO bintest (xint1, xbin)
	    VALUES(:i1, :b1)
	}]
	$stmt1 paramtype i1 integer
	$stmt1 paramtype b1 varbinary 256
	set stmt2 [db prepare {
	    SELECT xbin FROM bintest WHERE xint1 = :i1
	}]
	$stmt2 paramtype i1 integer
    }
    -body {
	set listdata {}
	for {set i 0} {$i < 256} {incr i} {
	    lappend listdata $i
	}
	set b1 [binary format c* $listdata]
	set i1 123
	$stmt1 allrows
	$stmt2 foreach -as lists row { set b2 [lindex $row 0] }
	list [string length $b2] [string compare $b1 $b2]
    }
    -result {256 0}
    -cleanup {
	$stmt1 close
	$stmt2 close
	db allrows {DROP TABLE bintest}
    }
}

test tdbc::postgres-22.1 {duplicate column name} {*}{
    -body {
	set stmt [::db prepare {
	    SELECT a.idnum, b.idnum 
	    FROM people a, people b
	    WHERE a.name = 'hud rockstone' 
	    AND b.info = a.info
	}]
	set rs [$stmt execute]
	$rs columns
    }
    -result {idnum idnum#2}
    -cleanup {
	$rs close
	$stmt close
    }
}

#-------------------------------------------------------------------------------

# Test cleanup. Get rid of the test database

catch {rename ::db {}}

cleanupTests
return

# Local Variables:
# mode: tcl
# End: