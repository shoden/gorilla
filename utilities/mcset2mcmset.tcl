#! /bin/sh
# the next line restarts using wish \
exec tclsh8.5 "$0" ${1+"$@"}

# Convert the output of GNU gettext msgfmt from plural calls to
# ::msgcat::mcset into a single call to ::msgcat::mcmset
#
# Copyright (c) 2011 by Richard Ellis

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 675 Mass Ave, Cambridge, MA 02139, USA.

# A copy of the GNU GPL may be found in the LICENCE.txt file in the main
# gorilla/sources directory.

# check command line parameters

if { [ llength $argv ] == 0 } {
  puts stderr "This utility should be called with a list of filenames as command line parameters."
  exit 1
}

foreach filename $argv {
  if {    ( ! [ file exists $filename ] ) 
       && ( ! [ file readable $filename ] ) } {
    lappend error_files $filename
  }
}

if { [ info exists error_files ] } {
  puts stderr "The following files were not found or are unreadable\n  [ join $error_files "\n  " ]"
  exit 1
}

# now the converstion system #

proc open.utf-8 { filename {access ""} {mode ""} } {
  # encapsulate adjustment of the file character set encoding
  
  set params [ list $filename ]
  if { $access ne "" } { 
    lappend params $access
  }
  if { $mode ne "" } {
    lappend params $mode
  }
  
  set fd [ open {*}$params ]
  fconfigure $fd -encoding utf-8
  return $fd
} ; # end proc open.utf-8

# fake msgcat proc that makes the magic work

namespace eval ::msgcat {

  variable msgdata

  proc mcset { lang fromstr tostr } {
    variable msgdata 
    dict lappend msgdata $lang $fromstr $tostr
  }

} ; # end namespace eval ::msgcat

# now read each file in and output a converted file

# converted output files will be named for the original filename with
# ".conv" appended.  Any existing ".conv" files will be silently overwritten

# Usually a single msg file will contain translations for a single language. 
# But this converter will convert and group plural language translations
# that might exist in a single input file.

foreach filename $argv {

  # the input half of the loop body

  # initialize for each new input file
  set ::msgcat::msgdata [ dict create ]
  unset -nocomplain ::msgcat::header

  set fd [ open.utf-8 $filename {RDONLY} ]

  # let the Tcl parser to the real work of parsing the input file
  eval [ read $fd ]
  
  close $fd

  # the output half of the loop body 
  
  set fd [ open.utf-8 ${filename}.conv {WRONLY CREAT TRUNC} ]
  
  if { [ info exists ::msgcat::header ] } {
    puts $fd "# [ join [ split [ string trim $::msgcat::header ] "\n" ] "\n# " ]\n"
  }

  # The loop below outputs a separate "mcmset lang { ... }" group for each
  # unique input language in the input file.
    
  dict for {key value} $::msgcat::msgdata {
    puts $fd "mcmset $key \{"
    foreach {to from} $value {
      puts $fd "[ list $to ] [ list $from ]"
    }
    puts $fd "\}"
  }
  
  close $fd   

} ; # end foreach filename $argv
