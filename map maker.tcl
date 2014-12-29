set startpts 10
set landfraction 0
set mapx 75
set mapy 35
set cellsize 8

set pcntdone 0

set count 0
set numciv 5
set maxterritory 1000
set winchance 0.2
set changchance 0.0
set rebchance 0.0004
set navymakechance 0.01
set navyavmove 100
set atktry 1
set on 1

proc viewconst {} {
	global winchance
	global changchance
	global rebchance
	global navymakechance
	global navyavmove
	global atktry
	puts "win chance: $winchance (winchance)"
	puts "Changecol chance: $changchance (changchance)"
	puts "Rebellion chance: $rebchance (rebchance)"
	puts "Navy make chance: $navymakechance (navymakechance)"
	puts "Av navy move: $navyavmove (navyavmove)"
	puts "Attack tries: $atktry (atktry)"
}

proc mouseclick {x y} {
	global mapx
	global mapy
	set size [expr {$mapx*$mapy}]
	
	set item [.map find overlapping $x $y $x $y]
	set coords [.map coords $item]
	
	set targt 0
	set targl 0

	set l [lindex $coords 0]
	set t [lindex $coords 1]
	set r [lindex $coords 2]
	set b [lindex $coords 3]
	set n 0
	if {$l>0 && $t>0} {
		while {$n<$size && $l!=$targl} {
			incr n
			set targl [lindex [.map coords cell($n)] 0]
		}
		while {$n<$size && $t!=$targt} {
			incr n $mapx
			set targt [lindex [.map coords cell($n)] 1]
		}
	}
	if {$n<$size && $n>0} {
		console show
		puts "Cell $n"
		puts "[.map itemcget cell($n) -fill]"
	}
}
#Outputs neighbours of n if map is x by y
proc getneigh {n x y} {
	set list "[expr {$n-$x-1}] [expr {$n-$x}] [expr {$n-$x+1}] [expr {$n-1}] [expr {$n+1}] [expr {$n+$x-1}] [expr {$n+$x}] [expr {$n+$x+1}]"
	set mtx [expr {($x+1)/2}]
	set mbx [expr {($x*($y-1)+(($x-1)/2))}]
		  if {$n==0} {							;#top left
		lset list 0 [expr {$x-2}]
		lset list 1 [expr {$x-1}]
		lset list 2 0
		lset list 3 [expr {$x-1}]
		lset list 5 [expr {2*$x-1}]
	} elseif {$n==($x-1)} {						;#top right
		lset list 0 $n
		lset list 1 0
		lset list 2 1
		lset list 4 0
		lset list 7 $x
	} elseif {$n==($x*($y-1))} {				;#bottom left
		lset list 0 [expr {$x*$y-1-$x}]
		lset list 3 [expr {$x*$y-1}]
		lset list 5 [expr {$x*$y-2}]
		lset list 6 [expr {$x*$y-1}]
		lset list 7 $n
	} elseif {$n==($x*$y-1)} {					;#bottom right
		lset list 2 [expr {$x*($y-1)-$x}]
		lset list 4 [expr {$x*($y-1)}]
		lset list 5 $n
		lset list 6 [expr {$x*2}]
		lset list 7 [expr {$x*2+1}]
	} elseif {$n<$x} {							;#top
		lset list 0 [expr {$x-1-$n-1}]
		lset list 1 [expr {$x-1-$n}]
		lset list 2 [expr {$x-1-$n+1}]
	} elseif {$n%$x==0} {						;#left
		lset list 0 [expr {$n-1}]
		lset list 3 [expr {$n+$x-1}]
		lset list 5 [expr {$n+2*$x-1}]
	} elseif {$n%$x==($x-1)} {					;#right
		lset list 2 [expr {$n-2*$x+1}]
		lset list 4 [expr {$n-$x+1}]
		lset list 7 [expr {$n+1}]
	} elseif {$n>=($x*($y-1))} {				;#bottom
		lset list 5 [expr {($x*$y-1)-($n-$x*($y-1))-1}]
		lset list 6 [expr {($x*$y-1)-($n-$x*($y-1))}]
		lset list 7 [expr {($x*$y-1)-($n-$x*($y-1))+1}]
	}
	return $list
}

#outputs a random neighbour of input "n". Gets all neighbours, then removes those not applicable for location  (top, corner etc.), then picks random one.
proc rndneigh {n x y} {
	set list [getneigh $n $x $y]
	set listlen [llength $list];incr listlen -1
	set index [expr {int(rand()*$listlen)}]
	set neighbour [lindex $list $index]
	return $neighbour
}

set clumping 1
proc makemap {} {
	global clumping
	global mapx
	global mapy
	global startpts
	global landfraction
	global cellsize
	upvar landlist landlist
	set mapsize [expr {$mapx*$mapy}]
	set maxland [expr {$mapsize*$landfraction}]
	set numland $startpts
	set landlist ""
	set activeland ""
	upvar pcntdone pcntdone
	
	#Make canvas
	destroy .map
	
	set green #00ff00
	set blue #0000ff
	
	set cx [expr {$mapx*$cellsize}]
	set cy [expr {$mapy*$cellsize}]
	canvas .map -width $cx -height $cy -bg blue
	grid .map -in .top -row 2 -column 1
	bind .map <ButtonPress-1> "mouseclick %x %y"


	#Create all cells on map
	for {set n 0} {$n<$mapsize} {incr n} {
		set ypos [expr {int(($n-1)/$mapx)}]
		set xpos [expr {($n+$mapx)%$mapx+1}]
		set t [expr {$ypos*$cellsize}]
		set b [expr {($ypos+1)*$cellsize}]
		set l [expr {($xpos-1)*$cellsize}]
		set r [expr {$xpos*$cellsize}]
		.map create rectangle $l $t $r $b -tag cell($n) -fill $blue -outline $blue
	}

	#Set start points
	for {set n 0} {$n<$startpts} {incr n} {
		set targ [expr {int(rand()*$mapsize)}]
		lappend landlist $targ
		.map  itemconfigure cell($targ) -fill $green -outline $green
	}
	
	#Show equator and meridian
	.map create line 0 [expr {$cy/2}] $cx [expr {$cy/2}] -fill black
	.map create line [expr {$cx/2}] 0 [expr {$cx/2}] $cy -fill black
	#Make land
	while {$numland<$maxland} {
		foreach land $activeland {
			for {set n 0} {$n<$clumping} {incr n} {
				set targ [rndneigh $land $mapx $mapy]
				if {[lsearch $landlist $targ]==-1} {incr numland;lappend landlist $targ;lappend activeland $targ;.map  itemconfigure cell($targ) -fill $green -outline $green} else {
					set index [lsearch $activeland $land];set activeland [lreplace $activeland $index $index]}
				after 1 {set sleep {}}
				tkwait variable sleep
			}
		}
		if {$activeland==""} {set activeland $landlist}
		set pcntdone "[expr {int($numland/$maxland*100)}]% done"
	}
	return 0
}
#outputs random col in form #RRGGBB
proc rndcol {} {
	set green #00ff00
	set blue #0000ff
	set r1 [expr {int(rand()*255)}]
	set g1 [expr {int(rand()*255)}]
	set b1 [expr {int(rand()*255)}]
	
	set r [format %x [expr {int(($r1>255 ? 255:$r1))}]]
		if {[string length $r]<2} {set r 0$r}
		if {[string length $r]>2} {set r ff}
	set g [format %x [expr {int(($g1>255 ? 255:$g1))}]]
		if {[string length $g]<2} {set g 0$g}
		if {[string length $g]>2} {set g ff}
	set b [format %x [expr {int(($b1>255 ? 255:$b1))}]]
		if {[string length $b]<2} {set b 0$b}
		if {[string length $b]>2} {set b ff}
		
	set col #$r$g$b
	if {[coldif $col $blue]<50 || [coldif $col $green]<50} {set col [rndcol]}
	return $col
}
#input 2 colours in form #RRGGBB, output dif in integer
proc coldif {a b} {
	set ar [expr 0x[string range $a 1 2]]
	set ag [expr 0x[string range $a 3 4]]
	set ab [expr 0x[string range $a 5 6]]
	set br [expr 0x[string range $b 1 2]]
	set bg [expr 0x[string range $b 3 4]]
	set bb [expr 0x[string range $b 5 6]]
	set rdif [expr {sqrt(($ar-$br)*($ar-$br))}]
	set gdif [expr {sqrt(($ag-$bg)*($ag-$bg))}]
	set bdif [expr {sqrt(($ab-$bb)*($ab-$bb))}]
	set dif [expr {int(($rdif+$gdif+$bdif)/3)}]
	return $dif
}
#input col in form #RRGGBB, output slightly changed col
proc mutcol {col} {
	set green #00ff00
	set blue #0000ff
	set ncol $green
	while {[coldif $ncol $green]<50 || [coldif $ncol $blue]<50} {
		set r [expr 0x[string range $col 1 2]]
		set g [expr 0x[string range $col 3 4]]
		set b [expr 0x[string range $col 5 6]]
		incr r [expr {int(rand()*10-5)}]
		incr g [expr {int(rand()*10-5)}]
		incr b [expr {int(rand()*10-5)}]
		set r [format %x [expr {int(($r>255 ? 255:$r))}]]
			if {[string length $r]<2} {set r 0$r}
			if {[string length $r]>2} {set r ff}
		set g [format %x [expr {int(($g>255 ? 255:$g))}]]
			if {[string length $g]<2} {set g 0$g}
			if {[string length $g]>2} {set g ff}
		set b [format %x [expr {int(($b>255 ? 255:$b))}]]
			if {[string length $b]<2} {set b 0$b}
			if {[string length $b]>2} {set b ff}
			
		set ncol #$r$g$b
	}
	return $ncol
}

proc onoff {} {
	upvar on on
	set on [expr {$on^1}]
}
proc playgame {} {
	global numciv
	global landlist
	global mapx
	global mapy
	global maxterritory
	set mapsize [expr {$mapx*$mapy}]
	set green #00ff00
	set blue #0000ff
	#initiate navy/army var
	for {set n 0} {$n<$mapsize} {incr n} {
		set navy($n) $blue
		set navdir($n) 0
		set army($n) [.map itemcget cell($n) -fill]
	}
	#Set start points
	for {set n 0} {$n<$numciv} {incr n} {
		set col [rndcol]
		set c($n) $col
		set length [llength $landlist];incr length -1
		set targ [expr {int(rand()*$length)}]
		set targ [lindex $landlist $targ]
		lappend activeland $targ
		lappend territory $targ
		set army($targ) $col
		.map  itemconfigure cell($targ) -fill $col -outline $col
	}
	set activesea ""
	set navies ""
	upvar count count
	global winchance
	global changchance
	global rebchance
	global navymakechance
	global navyavmove
	global atktry
	global on
	while {1} {
		while {$on} {
			foreach land $activeland {
				set col [.map itemcget cell($land) -fill]
				for {set n 0} {$n<$atktry} {incr n} {
					if {$col!=$green && $col!=$blue} {
						set targ [rndneigh $land $mapx $mapy]
						set targcol $army($targ)
						set coldif [coldif $col $targcol]
						if {rand()<$changchance} {set ncol [mutcol $col]} else {set ncol $col}
						#calc nwinchance
						set nwinchance $winchance
						set neigh2 [rndneigh $targ $mapx $mapy]
						for {set n 0} {$n<5 && [coldif $army($neigh2) $col]<=30} {incr n} {
							set nwinchance [expr {$nwinchance**0.5}]
							set neigh2 [rndneigh $neigh2 $mapx $mapy]
						}
						#target occupied land
						if {$coldif>30 && $targcol!=$blue && $targcol!=$green && rand()<$nwinchance} {
							lappend activeland $targ
							set army($targ) $ncol
							.map  itemconfigure cell($targ) -fill $ncol -outline $ncol
						#target empty land
						} elseif {$targcol==$green && $targcol!=$blue} {
							lappend activeland $targ;lappend territory $targ
							set army($targ) $ncol
							.map  itemconfigure cell($targ) -fill $ncol -outline $ncol
						#target occupied sea
						} elseif {$targcol==$blue && $navy($targ)!=$blue && rand()<$nwinchance} {
							lappend activesea $targ
							set navy($targ) $blue
	.map  itemconfigure cell($targ) -fill $blue -outline $blue
						#target empty sea
						} elseif {rand()<$navymakechance && $targcol==$blue && $navy($targ)==$blue} {
							lappend activesea $targ;lappend navies $targ
							set navy($targ) $ncol
							set navdir($targ) [expr {int(rand()*8)}]
	.map  itemconfigure cell($targ) -fill $blue -outline $ncol
						} else {
							set index [lsearch $activeland $land];set activeland [lreplace $activeland $index $index]
						}
					}
				}
				after 1 {set sleep {}}
				tkwait variable sleep

			}
			foreach sea $activesea {
				set col $navy($sea)
				if {$col!=$green && $col!=$blue} {
					set targ [lindex [getneigh $sea $mapx $mapy] $navdir($sea)]
					set targcol $navy($targ)
					set coldif [coldif $col $targcol]
					if {rand()<$changchance} {set ncol [mutcol $col]} else {set ncol $col}
					#target empty sea
					      if {[.map itemcget cell($targ) -fill]==$blue && $navy($targ)==$blue} {
						lappend activesea $targ;lappend navies $targ
						set navy($targ) $ncol
						set navdir($targ) $navdir($sea)
.map  itemconfigure cell($targ) -fill $blue -outline $ncol
					#target occupied sea
					} elseif {$coldif>30 && [.map itemcget cell($targ) -fill]==$blue && $navy($targ)!=$blue && rand()<$winchance} {
						lappend activesea $targ
						set navy($targ) $ncol
						set navdir($targ) $navdir($sea)
.map  itemconfigure cell($targ) -fill $blue -outline $ncol
					#target land
					} elseif {$army($targ)!=$blue} {
						set targcol $army($targ)
						set coldif [coldif $col $targcol]
						#target occupied land
						      if {$coldif>30 && $targcol!=$blue && $targcol!=$green} {
							lappend activeland $targ
							.map  itemconfigure cell($targ) -fill $ncol -outline $ncol
						#target empty land
						} elseif {[.map itemcget cell($targ) -fill]==$green} {
							lappend activeland $targ;lappend territory $targ
							.map  itemconfigure cell($targ) -fill $ncol -outline $ncol
						}
					}
					set navy($sea) $blue
					if {($targ>($mapx*($mapy-1)) && $sea>($mapx*($mapy-1))) || ($targ<$mapx && $sea<$mapx)} {set navdir($targ) [expr {int(rand()*8)}]}
					set index [lsearch $activesea $sea];set activesea [lreplace $activesea $index $index]
					set index [lsearch $navies $sea];set navies [lreplace $navies $index $index]
					if {rand()<(1/$navyavmove)} {set index [lsearch $activesea $targ];set activesea [lreplace $activesea $index $index]}
.map  itemconfigure cell($sea) -fill $blue -outline $blue
				}
				after 1 {set sleep {}}
				tkwait variable sleep
			}
			#while {[llength $territory]>$maxterritory} {
			#	set length [llength $territory];incr length -1
			#	set index [expr {int(rand()*$length)}]
			#	set targ [lindex $territory $index]
			#	.map  itemconfigure cell($targ) -fill green -outline green
			#	set territory [lreplace $territory $index $index]
			#}
			if {$activeland==""} {
				set activeland $territory;set activesea $navies;incr count
				set rebhappen [expr {$rebchance*[llength $territory]}]
				set intreb [expr {int($rebhappen)}]
				set rebhappen [expr {$rebhappen-int($rebhappen)}]
				
				while {$intreb>0} {
					set land [lindex $territory [expr {int(rand()*[llength $territory])}]]
					set col [rndcol]
					.map  itemconfigure cell($land) -fill $col -outline $col
					puts "Rebellion of $col at $count"
					puts [expr {$rebchance*[llength $territory]}]
					incr intreb -1
				}
				if  {rand()<$rebhappen} {
					set land [lindex $territory [expr {int(rand()*[llength $territory])}]]
					set col [rndcol]
					.map  itemconfigure cell($land) -fill $col -outline $col
					puts "Rebellion of $col at $count"
					puts [expr {$rebchance*[llength $territory]}]
				}
			}
			
		}
	after 1 {set sleep {}}
	tkwait variable sleep
	}
}


frame .top
frame .bottom
grid .top -in . -row 1 -column 1
grid .bottom -in . -row 2 -column 1

label .count -textvariable count
grid .count -in .top -row 1 -column 1

set cx [expr {$mapx*$cellsize}]
set cy [expr {$mapy*$cellsize}]
canvas .map -width $cx -height $cy -bg blue
grid .map -in .top -row 2 -column 1

label .lclump -text "Clumping factor:"
entry .clump -textvariable clumping

grid .lclump -in .bottom -row 1 -column 5
grid .clump -in .bottom -row 2 -column 5

button .start -text "Make map" -command "makemap"
grid .start -in .bottom -row 1 -column 1
label .done -textvariable pcntdone
grid .done -in .bottom -row 2 -column 1

label .lstartpts -text "Start points:"
entry .startpts -textvariable startpts
label .llandfraction -text "Land fraction:"
entry .landfraction -textvariable landfraction
label .lmapx -text "Map X:"
entry .mapx -textvariable mapx
label .lmapy -text "Map Y:"
entry .mapy -textvariable mapy
label .lcellsize -text "Cell size:"
entry .cellsize -textvariable cellsize

grid .lstartpts -in .bottom -row 3 -column 1
grid .startpts -in .bottom -row 4 -column 1
grid .llandfraction -in .bottom -row 3 -column 2
grid .landfraction -in .bottom -row 4 -column 2
grid .lmapx -in .bottom -row 3 -column 3
grid .mapx -in .bottom -row 4 -column 3
grid .lmapy -in .bottom -row 3 -column 4
grid .mapy -in .bottom -row 4 -column 4
grid .lcellsize -in .bottom -row 3 -column 5
grid .cellsize -in .bottom -row 4 -column 5

label .lnumciv -text "Num civ:"
entry .numciv -textvariable numciv
label .lmaxterritory -text "Max territory:"
entry .maxterritory -textvariable maxterritory

grid .lnumciv -in .bottom -row 1 -column 2
grid .numciv -in .bottom -row 2 -column 2
grid .lmaxterritory -in .bottom -row 1 -column 3
grid .maxterritory -in .bottom -row 2 -column 3

button .play -text "Play gane" -command "playgame"
grid .play -in .bottom -row 1 -column 4