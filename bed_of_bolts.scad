/**
Run get_deps.sh to clone dependencies into a linked folder in your home directory.
*/

use <deps.link/BOSL/nema_steppers.scad>
use <deps.link/BOSL/joiners.scad>
use <deps.link/BOSL/shapes.scad>
use <deps.link/BOSL/acme_screws.scad>
use <deps.link/BOSL/metric_screws.scad>
use <deps.link/erhannisScad/misc.scad>
use <deps.link/erhannisScad/auto_lid.scad>
use <deps.link/scadFluidics/common.scad>
use <deps.link/quickfitPlate/blank_plate.scad>
use <deps.link/getriebe/Getriebe.scad>
use <deps.link/gearbox/gearbox.scad>

$FOREVER = 1000;
DUMMY = false;
$fn = DUMMY ? 10 : 60;

//RAINY Maybe a SCALE variable?

SCALE = 1.0;
SLOP = 0.25;
SLOP2 = SLOP*2;
BOLT_OD = 10*SCALE;
BOLT_RETAINER_T = 2*SCALE; //THINK Not sure abt scale
BOLT_RETAINER_L = 15*SCALE;
BOLT_RETAINER_D = BOLT_OD*0.2;
NON_LOAD_T = 1; //THINK Maybe scale?

module TransferSleeve() {
}

module Bolt() {
  //RAINY I like the look of the trapezoidal threaded rod, but it probably sucks to print, so normal threaded rod it is, for now.
  difference() {
    threaded_rod(d=BOLT_OD);
    cmy() ty((BOLT_OD/2)-BOLT_RETAINER_D) ty(-SLOP) translate([-(BOLT_RETAINER_T+SLOP2)/2,0,-$FOREVER/2]) cube([BOLT_RETAINER_T+SLOP2, $FOREVER, $FOREVER]);
  }
}

module Housing() {
}

module ClutchGear() {
}

module DriveSleeve() {
}

// The retainer itself doesn't apply force; it just positions the key fins for the bolt and the housing.
module BoltRetainer() {
  // Flange
  difference() {
    cylinder(d=BOLT_OD*1.5,h=NON_LOAD_T);
    cylinder(d=BOLT_OD+SLOP2,h=$FOREVER,center=true);
  }
  
  // Fins
  cmy() mz() ty((BOLT_OD/2)-BOLT_RETAINER_D) tx(-BOLT_RETAINER_T/2) cube([BOLT_RETAINER_T, BOLT_RETAINER_D*2, BOLT_RETAINER_L]);
}

module Assembly() {
  Housing();
  Bolt();
  DriveSleeve();
  TransferSleeve();
  ClutchGear();
  BoltRetainer(); //CHECK Maybe top AND bottom?
}




difference() {
  Assembly();
//  OXp();
}

// schnecke(modul=1, gangzahl=2, laenge=15, bohrung=4, eingriffswinkel=20, steigungswinkel=10, zusammen_gebaut=true);

// schneckenradsatz(modul=1, zahnzahl=30, gangzahl=2, breite=8, laenge=20, bohrung_schnecke=4, bohrung_rad=4, eingriffswinkel=20, steigungswinkel=10, optimiert=true, zusammen_gebaut=true);