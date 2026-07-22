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
MKFN = $fn;

//RAINY Maybe a SCALE variable?

SCALE = 1.0;
SLOP = 0.25;
SLOP2 = SLOP*2;
BOLT_OD = 10*SCALE;
BOLT_RETAINER_T = 2*SCALE; //THINK Not sure abt scale
BOLT_RETAINER_L = 15*SCALE;
BOLT_RETAINER_D = BOLT_OD*0.2;
NON_LOAD_T = 1; //THINK Maybe scale?

TRANSFER_WALL = 2*SCALE;
TRANSFER_TEETH = ceil(15*SCALE);
INTERLOCK_SZ = 10*SCALE;
TRANSFER_SZ = 2*INTERLOCK_SZ;
HOHLRAD_OD = 2*TRANSFER_WALL + pfeilrad_dims(modul=1, zahnzahl=TRANSFER_TEETH, breite=TRANSFER_SZ, bohrung=BOLT_OD+SLOP2, eingriffswinkel=20, schraegungswinkel=0, optimiert=false)[0];

module TransferStirnrad(sz=TRANSFER_SZ,bore=BOLT_OD+SLOP2,chamfer1=true,chamfer2=true) {
  difference() {
    stirnrad(modul=1, zahnzahl=TRANSFER_TEETH, breite=sz, bohrung=bore, eingriffswinkel=20, schraegungswinkel=0, optimiert=false);
    if (chamfer1) {
      TransferChamfersInner();
    }
    if (chamfer2) {
      tz(sz) TransferChamfersInner();
    }
  }
}

module TransferHohlrad(sz=TRANSFER_SZ,chamfer1=true,chamfer2=true) {
  difference() {
    // Bulk
    cylinder(d=HOHLRAD_OD,h=sz);
    // Gear pattern
    minkowski() {
      stirnrad(modul=1, zahnzahl=TRANSFER_TEETH, breite=sz, bohrung=BOLT_OD+SLOP2, eingriffswinkel=20, schraegungswinkel=0, optimiert=false);
      cylinder(d=SLOP,h=0.01,center=true,$fn=MKFN);
    }
    // Central hole
    cylinder(d=BOLT_OD+SLOP2,h=$FOREVER,center=true);
    // Chamfers
    if (chamfer1) {
      TransferChamfersOuter();
    }
    if (chamfer2) {
      tz(sz) TransferChamfersOuter();
    }
  }
}

module TransferBlank() {

}

module TransferSleeve() {
  TransferStirnrad(chamfer1=false);
  tz(-1*INTERLOCK_SZ) difference() {
    cylinder(d=HOHLRAD_OD, h=INTERLOCK_SZ);
    cylinder(d=BOLT_OD+SLOP2, h=INTERLOCK_SZ);
  }
  tz(-3*INTERLOCK_SZ) TransferHohlrad(chamfer2=false);
}

module BoltCore(negative=false) {
  if (negative) {
//    minkowski() {
//      BoltCore(negative=false);
//      cylinder(d=SLOP2,h=0.01,center=true,$fn=MKFN);
//    }
    threaded_rod(d=BOLT_OD+SLOP2);
  } else {
    threaded_rod(d=BOLT_OD);
  }
}

module Bolt() {
  //RAINY I like the look of the trapezoidal threaded rod, but it probably sucks to print, so normal threaded rod it is, for now.
  difference() {
    BoltCore();
    cmy() ty((BOLT_OD/2)-BOLT_RETAINER_D) ty(-SLOP) translate([-(BOLT_RETAINER_T+SLOP2)/2,0,-$FOREVER/2]) cube([BOLT_RETAINER_T+SLOP2, $FOREVER, $FOREVER]);
  }
}

module Housing() {
}

module ClutchGear() {
}

module DriveSleeveA() {

}

DRIVE_SLEEVE_B_FLANGE_D = (BOLT_OD+10*2)*SCALE;
DRIVE_SLEEVE_B_FLANGE_T = 5*SCALE;

module DriveSleeveB() {
  difference() {
    union() {
      mz() cylinder(d=DRIVE_SLEEVE_B_FLANGE_D,h=DRIVE_SLEEVE_B_FLANGE_T);
      TransferStirnrad(bore=0,chamfer1=false);
    }
    BoltCore(negative=true);
  }
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
  DriveSleeveA();
  //tz(-30) DriveSleeveB();
  tz(SLOP) TransferSleeve();
  ClutchGear();
  tz(45) BoltRetainer(); //CHECK Maybe top AND bottom?
}




*difference() {
  Assembly();
  OXp();
}

difference() {
  BoltCore(negative=true);
  BoltCore(negative=false);
  OXp();
}

// schnecke(modul=1, gangzahl=2, laenge=15, bohrung=4, eingriffswinkel=20, steigungswinkel=10, zusammen_gebaut=true);

// schneckenradsatz(modul=1, zahnzahl=30, gangzahl=2, breite=8, laenge=20, bohrung_schnecke=4, bohrung_rad=4, eingriffswinkel=20, steigungswinkel=10, optimiert=true, zusammen_gebaut=true);

module TransferChamfersOuter() {
  minkowski() {
    stirnrad(modul=1, zahnzahl=TRANSFER_TEETH, breite=0.01, bohrung=BOLT_OD+SLOP2, eingriffswinkel=20, schraegungswinkel=0, optimiert=false);
    cmz() cylinder(d1=1,d2=0,h=1,$fn=MKFN);
  }
}

module TransferChamfersInner() {
  minkowski() {
    hohlrad(modul=1, zahnzahl=TRANSFER_TEETH, breite=0.01, randbreite=3, eingriffswinkel=20, schraegungswinkel=0);
    cmz() cylinder(d1=1,d2=0,h=1,$fn=MKFN);
  }
}
